#!/usr/bin/env python3
"""Remind me to switch models as Codex quota is consumed."""

import json
import os
import select
import subprocess
import sys
import time
import unittest
from pathlib import Path


PARETO_MODELS = [
    "Astra max",
    "Astra xhigh",
    "Astra high",
    "Astra medium",
    "Astra low",
    "Sol medium",
    "Luna max",
    "Luna xhigh",
    "Luna high",
    "Luna medium",
    "Luna low",
]
ORIGINAL_BANDS = [
    (100, 87.5),
    (87.5, 75),
    (75, 62.5),
    (62.5, 50),
    (50, 37.5),
    (37.5, 25),
    (25, 20),
    (20, 15),
    (15, 10),
    (10, 5),
    (5, 0),
]
FALLBACK = [
    (
        mode,
        round(offset + high / 2, 6),
        round(offset + low / 2, 6),
        model,
    )
    for mode, offset in (("Fast", 50), ("Standard", 0))
    for (high, low), model in zip(ORIGINAL_BANDS, PARETO_MODELS)
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
    duration = window.get("windowDurationMins")
    return 100 - used, f"{format_duration(duration)} window"


def format_duration(minutes: object) -> str:
    if not isinstance(minutes, (int, float)):
        return "quota"
    days, remainder = divmod(int(minutes), 24 * 60)
    hours, minutes = divmod(remainder, 60)
    return f"{days}d{hours}h{minutes}m"


def target_model(remaining: float) -> tuple[str, float] | None:
    for mode, high, low, model in FALLBACK[1:]:
        if low < remaining <= high:
            return f"{mode}: {model}", high
    if remaining <= FALLBACK[-1][1]:
        mode, high, _, model = FALLBACK[-1]
        return f"{mode}: {model}", high
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
        notify(
            f"{remaining:.0f}% remaining in {window}. "
            f"Do not use any models better than {model}."
        )

    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps({"model": model, "threshold": threshold}))


class ScheduleTests(unittest.TestCase):
    def test_each_mode_repeats_the_pareto_sequence(self) -> None:
        self.assertEqual(
            [stage[3] for stage in FALLBACK[: len(PARETO_MODELS)]], PARETO_MODELS
        )
        self.assertEqual(
            [stage[3] for stage in FALLBACK[len(PARETO_MODELS) :]], PARETO_MODELS
        )

    def test_modes_meet_at_fifty_percent(self) -> None:
        self.assertEqual(FALLBACK[10][2], 50)
        self.assertEqual(FALLBACK[11][1], 50)
        self.assertEqual(FALLBACK[0][1], 100)
        self.assertEqual(FALLBACK[-1][2], 0)

    def test_luna_stays_in_each_half_bottom_quarter(self) -> None:
        self.assertEqual(FALLBACK[6][1:3], (62.5, 60.0))
        self.assertEqual(FALLBACK[17][1:3], (12.5, 10.0))

    def test_scaled_band_widths(self) -> None:
        fast_widths = [high - low for _, high, low, _ in FALLBACK[:6]]
        fast_luna_widths = [high - low for _, high, low, _ in FALLBACK[6:11]]
        standard_widths = [high - low for _, high, low, _ in FALLBACK[11:17]]
        standard_luna_widths = [high - low for _, high, low, _ in FALLBACK[17:]]
        self.assertEqual(fast_widths, [6.25] * 6)
        self.assertEqual(fast_luna_widths, [2.5] * 5)
        self.assertEqual(standard_widths, [6.25] * 6)
        self.assertEqual(standard_luna_widths, [2.5] * 5)

    def test_transition_targets(self) -> None:
        self.assertIsNone(target_model(100))
        self.assertEqual(target_model(93.75), ("Fast: Astra xhigh", 93.75))
        self.assertEqual(target_model(62.5), ("Fast: Luna max", 62.5))
        self.assertEqual(target_model(50), ("Standard: Astra max", 50.0))
        self.assertEqual(target_model(12.5), ("Standard: Luna max", 12.5))
        self.assertEqual(target_model(0), ("Standard: Luna low", 2.5))

    def test_remaining_uses_the_most_constrained_window(self) -> None:
        result = {
            "rateLimits": {
                "primary": {"usedPercent": 30, "windowDurationMins": 15},
                "secondary": {"usedPercent": 70, "windowDurationMins": 10080},
            }
        }
        self.assertEqual(remaining_percent(result), (30.0, "7d0h0m window"))

    def test_formats_quota_window_duration(self) -> None:
        self.assertEqual(format_duration(15), "0d0h15m")
        self.assertEqual(format_duration(90), "0d1h30m")
        self.assertEqual(format_duration(1500), "1d1h0m")
        self.assertEqual(format_duration(10080), "7d0h0m")


if __name__ == "__main__":
    if "--test" in sys.argv:
        unittest.main(argv=[sys.argv[0]])
    else:
        try:
            main()
        except Exception as error:
            # A reminder must never disrupt a Codex turn.
            if os.environ.get("CODEX_MODEL_REMINDER_DEBUG") == "1":
                print(f"model-switch-reminder: {error}", file=sys.stderr)
