#!/usr/bin/env python3
"""Remind me to switch models as Codex quota is consumed."""

import json
import os
import select
import subprocess
import sys
import time
from pathlib import Path


# Each range names the model to use while remaining quota is in that range.
FALLBACK = [
    (100, 75, "Astra fast"),
    (75, 50, "Astra"),
    (50, 25, "Sol fast"),
    (25, 10, "Sol"),
    (10, 5, "Terra fast"),
    (5, 2, "Terra"),
    (2, 1, "Luna fast"),
    (1, 0, "Luna"),
]
STATE_PATH = Path("~/.codex/model-switch-reminder-state.json").expanduser()
CODEX = os.environ.get("CODEX_BIN", "/Users/bytedance/.local/bin/codex")


def read_rate_limits() -> dict[str, object]:
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
    process = subprocess.Popen(
        [CODEX, "app-server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        env={
            **os.environ,
            "CODEX_HOME": os.environ.get(
                "CODEX_HOME", str(Path("~/.codex").expanduser())
            ),
        },
    )
    try:
        process.stdin.write(
            "\n".join(json.dumps(message) for message in messages) + "\n"
        )
        process.stdin.flush()
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            ready, _, _ = select.select(
                [process.stdout], [], [], max(0, deadline - time.monotonic())
            )
            if not ready:
                break
            line = process.stdout.readline()
            if not line:
                break
            message = json.loads(line)
            if message.get("id") == 2:
                return message["result"]
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    raise RuntimeError("account/rateLimits/read returned no result")


def remaining_percent(result: dict[str, object]) -> tuple[float, str]:
    buckets = result.get("rateLimitsByLimitId", {})
    snapshot = buckets.get("codex") if isinstance(buckets, dict) else None
    if not isinstance(snapshot, dict):
        snapshot = result["rateLimits"]

    windows = [snapshot.get(name) for name in ("primary", "secondary")]
    windows = [window for window in windows if isinstance(window, dict)]
    used, window = max(
        ((float(window["usedPercent"]), window) for window in windows),
        key=lambda item: item[0],
    )
    duration = window.get("windowDurationMins", "quota")
    return 100 - used, f"{duration}-minute window"


def target_model(remaining: float) -> tuple[str, int] | None:
    for high, low, model in FALLBACK[1:]:
        if low < remaining <= high:
            return model, high
    if remaining <= FALLBACK[-1][1]:
        return FALLBACK[-1][2], FALLBACK[-1][0]
    return None


def notify(message: str) -> None:
    escaped = message.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(
        [
            "/usr/bin/osascript",
            "-e",
            f'display notification "{escaped}" with title "Codex model reminder"',
        ],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=5,
    )


def main() -> None:
    hook_input = json.load(sys.stdin)
    remaining, window = remaining_percent(read_rate_limits())
    target = target_model(remaining)
    if target is None:
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(json.dumps({"model": None}))
        return
    model, threshold = target

    try:
        previous = json.loads(STATE_PATH.read_text())
    except FileNotFoundError:
        previous = {}

    if previous.get("model") != model:
        current = hook_input.get("model", "the current model")
        notify(
            f"{remaining:.0f}% remaining in {window}. "
            f"Switch from {current} to {model}."
        )

    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps({"model": model, "threshold": threshold}))


try:
    main()
except Exception as error:
    # A reminder must never disrupt a Codex turn.
    if os.environ.get("CODEX_MODEL_REMINDER_DEBUG") == "1":
        print(f"model-switch-reminder: {error}", file=sys.stderr)
