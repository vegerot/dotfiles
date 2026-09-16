#!/usr/bin/env python3
"""Schedule one future Codex turn at a time in the current conversation."""

import argparse
from contextlib import contextmanager
import fcntl
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path
from typing import Iterator, Literal, NotRequired, TypedDict, cast


LoopMode = Literal["fixed", "adaptive"]
JobStatus = Literal["scheduled", "queued", "running", "completed", "canceled", "expired", "failed"]


class Job(TypedDict):
    id: str
    thread_id: str
    codex: str
    prompt: str
    mode: LoopMode
    seconds: int
    generation: int
    status: JobStatus
    created_at: float
    expires_at: float
    next_at: float | None
    error: NotRequired[str]


STATE_DIR: Path = Path(
    os.environ.get(
        "CODEX_LOOP_STATE_DIR",
        str(Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "loop-jobs"),
    )
)
LIFETIME_SECONDS: int = 7 * 24 * 60 * 60
PROBE_THREAD: str = "00000000-0000-0000-0000-000000000001"


def prepare_dir() -> None:
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)


def job_path(job_id: str) -> Path:
    return STATE_DIR / f"{uuid.UUID(job_id).hex}.json"


def read_job(job_id: str) -> Job:
    path = job_path(job_id)
    if not path.exists():
        raise SystemExit(f"Loop {job_id} was not found")
    return cast(Job, json.loads(path.read_text(encoding="utf-8")))


def save_job(job: Job) -> None:
    prepare_dir()
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=STATE_DIR, delete=False
    ) as temporary:
        json.dump(job, temporary)
        temporary.write("\n")
        temp_path = temporary.name
    os.chmod(temp_path, 0o600)
    os.replace(temp_path, job_path(job["id"]))


@contextmanager
def locked() -> Iterator[None]:
    prepare_dir()
    with (STATE_DIR / ".lock").open("a+") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        yield


def print_job(job: Job) -> None:
    print(json.dumps(job, indent=2, sort_keys=True))


def start_timer(job: Job, seconds: int) -> None:
    subprocess.Popen(
        [
            sys.executable,
            str(Path(__file__).resolve()),
            "_fire",
            job["id"],
            str(job["generation"]),
            str(seconds),
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def check_queue(codex: str) -> None:
    daemon = subprocess.run(
        [codex, "app-server", "daemon", "version"],
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    if daemon.returncode != 0 or '"status":"running"' not in daemon.stdout:
        raise SystemExit("A running local Codex app-server daemon is required")
    probe = subprocess.run(
        [codex, "queue", "--thread", PROBE_THREAD, "--message", "probe"],
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    if "no rollout found for thread id" not in probe.stderr:
        raise SystemExit(f"Codex queue is unavailable: {probe.stderr.strip()}")


def command_start(args: argparse.Namespace) -> None:
    thread_id = os.environ.get("CODEX_THREAD_ID")
    if not thread_id:
        raise SystemExit("CODEX_THREAD_ID is missing; start a loop from a Codex shell tool")
    uuid.UUID(thread_id)
    if args.seconds < 1:
        raise SystemExit("The delay must be positive")
    codex = shutil.which("codex")
    if not codex:
        raise SystemExit("codex is not on PATH")
    check_queue(codex)
    now = time.time()
    job: Job = {
        "id": uuid.uuid4().hex,
        "thread_id": thread_id,
        "codex": codex,
        "prompt": args.prompt,
        "mode": args.mode,
        "seconds": args.seconds,
        "generation": 1,
        "status": "scheduled",
        "created_at": now,
        "expires_at": now + LIFETIME_SECONDS,
        "next_at": now + args.seconds,
    }
    with locked():
        save_job(job)
        try:
            start_timer(job, args.seconds)
        except OSError as error:
            job["status"] = "failed"
            job["error"] = str(error)
            save_job(job)
            raise
    print_job(job)


def command_fire(args: argparse.Namespace) -> None:
    time.sleep(args.seconds)
    with locked():
        job = read_job(args.job_id)
        if job["generation"] != args.generation or job["status"] != "scheduled":
            return
        if time.time() >= job["expires_at"]:
            job["status"] = "expired"
            save_job(job)
            return
        job["status"] = "queued"
        save_job(job)
    skill_path = Path(__file__).resolve().parent.parent / "SKILL.md"
    message = (
        f"$loop resume {job['id']} {args.generation}. "
        f"This is a scheduled iteration, not a new loop. "
        f"Read {skill_path} and follow its Scheduled iteration instructions. "
        f"Claim this job before doing any work."
    )
    try:
        queued = subprocess.run(
            [job["codex"], "queue", "--thread", job["thread_id"], "--message", message],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        error = (queued.stderr.strip() or "codex queue failed") if queued.returncode else None
    except (OSError, subprocess.TimeoutExpired) as failure:
        error = str(failure)
    if error:
        with locked():
            job = read_job(args.job_id)
            if job["generation"] == args.generation and job["status"] == "queued":
                job["status"] = "failed"
                job["error"] = error
                save_job(job)


def command_claim(args: argparse.Namespace) -> None:
    with locked():
        job = read_job(args.job_id)
        if job["generation"] != args.generation or job["status"] != "queued":
            raise SystemExit(f"Loop is {job['status']} or this tick is stale")
        job["status"] = "running"
        job["next_at"] = None
        save_job(job)
    print_job(job)


def command_next(args: argparse.Namespace) -> None:
    with locked():
        job = read_job(args.job_id)
        if job["generation"] != args.generation or job["status"] != "running":
            raise SystemExit(f"Loop is {job['status']} or this tick is stale")
        seconds = job["seconds"] if job["mode"] == "fixed" else args.seconds
        if seconds is None or seconds < 1:
            raise SystemExit("An adaptive loop needs a positive --seconds value")
        expired = time.time() >= job["expires_at"]
        if expired:
            job["status"] = "expired"
        else:
            job["generation"] += 1
            job["status"] = "scheduled"
            job["next_at"] = time.time() + seconds
        save_job(job)
        if not expired:
            try:
                start_timer(job, seconds)
            except OSError as error:
                job["status"] = "failed"
                job["error"] = str(error)
                save_job(job)
                raise
    print_job(job)


def command_stop(args: argparse.Namespace) -> None:
    with locked():
        job = read_job(args.job_id)
        if job["status"] not in ("completed", "canceled", "expired"):
            job["status"] = args.reason
            job["next_at"] = None
            save_job(job)
    print_job(job)


def command_update(args: argparse.Namespace) -> None:
    with locked():
        job = read_job(args.job_id)
        if job["status"] in ("completed", "canceled", "expired", "failed"):
            raise SystemExit(f"Cannot update a loop that is {job['status']}")
        job["prompt"] = args.prompt
        save_job(job)
    print_job(job)


def command_list(_args: argparse.Namespace) -> None:
    prepare_dir()
    thread_id = os.environ.get("CODEX_THREAD_ID")
    jobs: list[Job] = []
    for path in STATE_DIR.glob("*.json"):
        job = cast(Job, json.loads(path.read_text(encoding="utf-8")))
        if not thread_id or job["thread_id"] == thread_id:
            jobs.append(job)
    for job in sorted(jobs, key=lambda item: item["created_at"]):
        print_job(job)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    start = commands.add_parser("start")
    start.add_argument("--mode", choices=("fixed", "adaptive"), required=True)
    start.add_argument("--seconds", type=int, required=True)
    start.add_argument("--prompt", required=True)
    start.set_defaults(func=command_start)
    fire = commands.add_parser("_fire")
    fire.add_argument("job_id")
    fire.add_argument("generation", type=int)
    fire.add_argument("seconds", type=int)
    fire.set_defaults(func=command_fire)
    claim = commands.add_parser("claim")
    claim.add_argument("job_id")
    claim.add_argument("generation", type=int)
    claim.set_defaults(func=command_claim)
    following = commands.add_parser("next")
    following.add_argument("job_id")
    following.add_argument("generation", type=int)
    following.add_argument("--seconds", type=int)
    following.set_defaults(func=command_next)
    stop = commands.add_parser("stop")
    stop.add_argument("job_id")
    stop.add_argument("--reason", choices=("completed", "canceled"), required=True)
    stop.set_defaults(func=command_stop)
    update = commands.add_parser("update")
    update.add_argument("job_id")
    update.add_argument("--prompt", required=True)
    update.set_defaults(func=command_update)
    show = commands.add_parser("show")
    show.add_argument("job_id")
    show.set_defaults(func=lambda args: print_job(read_job(args.job_id)))
    listing = commands.add_parser("list")
    listing.set_defaults(func=command_list)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
