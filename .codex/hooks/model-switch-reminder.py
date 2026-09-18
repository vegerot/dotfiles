#!/usr/bin/env python3
"""Remind me to switch Codex models as the account quota is consumed.

This is intentionally a passive Stop hook: it never blocks or continues a turn.
The policy lives in agent-comparison.md; this script only reads its fallback plan,
reads the current quota through the supported App Server protocol, and displays a
macOS notification when a lower-capacity band is crossed.
"""

import fcntl
import json
import os
import re
import selectors
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


DEFAULT_POLICY_PATH = Path(
    "/Users/bytedance/code/github.com/vegerot/ai-conversations/agent-comparison.md"
)
DEFAULT_STATE_PATH = Path("~/.codex/model-switch-reminder-state.json").expanduser()
DEFAULT_CODEX = "/Users/bytedance/.local/bin/codex"
POLICY_LINE = re.compile(
    r"^\s*[*-]\s*(?P<high>\d+)%\s*->\s*(?P<low>\d+)%\s*:?\s+(?P<model>.+?)\s*$"
)


def policy_path() -> Path:
    return Path(os.environ.get("CODEX_MODEL_POLICY_FILE", DEFAULT_POLICY_PATH))


def state_path() -> Path:
    return Path(
        os.environ.get("CODEX_MODEL_REMINDER_STATE", str(DEFAULT_STATE_PATH))
    ).expanduser()


def read_policy(path: Path) -> list[tuple[int, str]]:
    """Return (remaining-percent-threshold, next-model) transitions."""
    in_fallback_section = False
    bands: list[tuple[int, int, str]] = []

    for line in path.read_text().splitlines():
        if line.startswith("## "):
            in_fallback_section = line.strip().casefold() == "## model fallback plan"
            continue
        if not in_fallback_section:
            continue
        match = POLICY_LINE.match(line)
        if match:
            high = int(match.group("high"))
            low = int(match.group("low"))
            model = match.group("model")
            if high <= low:
                raise ValueError(f"invalid fallback range: {line}")
            bands.append((high, low, model))

    if len(bands) < 2:
        raise ValueError(f"no usable fallback plan found in {path}")

    transitions: list[tuple[int, str]] = []
    for previous, current in zip(bands, bands[1:]):
        if previous[1] != current[0]:
            raise ValueError("fallback ranges must be contiguous")
        transitions.append((current[0], current[2]))
    return transitions


def target_for_remaining(
    remaining_percent: float, transitions: list[tuple[int, str]]
) -> tuple[int, str] | None:
    remaining_percent = max(0.0, min(100.0, remaining_percent))
    for index, (upper_bound, model) in enumerate(transitions):
        lower_bound = (
            transitions[index + 1][0] if index + 1 < len(transitions) else -1
        )
        if lower_bound < remaining_percent <= upper_bound:
            return upper_bound, model
    return None


def _codex_command() -> str:
    configured = os.environ.get("CODEX_BIN")
    if configured:
        return configured
    return shutil.which("codex") or DEFAULT_CODEX


def read_rate_limits(timeout_seconds: float = 4.0) -> dict[str, Any] | None:
    """Read one current account/rateLimits snapshot from a short-lived app-server."""
    environment = os.environ.copy()
    environment.setdefault("CODEX_HOME", str(Path("~/.codex").expanduser()))
    process = subprocess.Popen(
        [_codex_command(), "app-server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        env=environment,
    )
    assert process.stdin is not None
    assert process.stdout is not None

    messages = [
        {
            "method": "initialize",
            "id": 1,
            "params": {
                "clientInfo": {
                    "name": "model_switch_reminder",
                    "title": "Codex model switch reminder",
                    "version": "1.0.0",
                }
            },
        },
        {"method": "initialized", "params": {}},
        {"method": "account/rateLimits/read", "id": 2},
    ]

    try:
        process.stdin.write("".join(json.dumps(message) + "\n" for message in messages))
        process.stdin.flush()

        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout_seconds
        while time.monotonic() < deadline:
            events = selector.select(max(0.0, deadline - time.monotonic()))
            if not events:
                break
            line = process.stdout.readline()
            if not line:
                break
            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                continue
            if message.get("id") != 2:
                continue
            result = message.get("result")
            return result if isinstance(result, dict) else None
    finally:
        selector.close()
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    return None


def current_usage(result: dict[str, Any]) -> tuple[float, str] | None:
    buckets = result.get("rateLimitsByLimitId")
    snapshot: dict[str, Any] | None = None
    if isinstance(buckets, dict):
        candidate = buckets.get("codex")
        if isinstance(candidate, dict):
            snapshot = candidate
    if snapshot is None and isinstance(result.get("rateLimits"), dict):
        snapshot = result["rateLimits"]
    if snapshot is None:
        return None

    windows: list[tuple[float, str]] = []
    for window_name in ("primary", "secondary"):
        window = snapshot.get(window_name)
        if not isinstance(window, dict):
            continue
        used = window.get("usedPercent")
        if isinstance(used, (int, float)):
            duration = window.get("windowDurationMins")
            label = f"{duration}-minute window" if duration else window_name
            windows.append((float(used), label))

    if not windows:
        return None
    used_percent, label = max(windows, key=lambda item: item[0])
    return max(0.0, min(100.0, 100.0 - used_percent)), label


def load_state(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def save_state(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}."
    ) as temporary:
        json.dump(value, temporary, sort_keys=True)
        temporary.write("\n")
        temporary.flush()
        os.fsync(temporary.fileno())
        os.replace(temporary.name, path)


def notify(message: str) -> None:
    escaped = message.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")
    script = f'display notification "{escaped}" with title "Codex model reminder"'
    subprocess.run(
        ["/usr/bin/osascript", "-e", script],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=5,
    )


def run(payload: dict[str, Any]) -> None:
    transitions = read_policy(policy_path())
    result = read_rate_limits()
    if result is None:
        return
    usage = current_usage(result)
    if usage is None:
        return

    remaining_percent, window_label = usage
    target = target_for_remaining(remaining_percent, transitions)
    path = state_path()
    lock_path = path.with_suffix(path.suffix + ".lock")
    lock_path.parent.mkdir(parents=True, exist_ok=True)

    with lock_path.open("w") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        state = load_state(path)
        previous_threshold = state.get("threshold")
        threshold = target[0] if target else None
        should_notify = (
            threshold is not None
            and (
                previous_threshold is None
                or not isinstance(previous_threshold, (int, float))
                or threshold < previous_threshold
            )
        )
        save_state(
            path,
            {
                "threshold": threshold,
                "remaining_percent": round(remaining_percent, 1),
                "updated_at": int(time.time()),
            },
        )
        if should_notify and target is not None:
            active_model = payload.get("model") or "the current model"
            notify(
                f"{remaining_percent:.0f}% remaining in {window_label}. "
                f"Switch from {active_model} to {target[1]}."
            )


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        run(payload if isinstance(payload, dict) else {})
    except Exception as error:  # A reminder must never disrupt a Codex turn.
        if os.environ.get("CODEX_MODEL_REMINDER_DEBUG") == "1":
            print(f"model-switch-reminder: {error}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
