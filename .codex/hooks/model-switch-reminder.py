#!/usr/bin/env python3
"""Remind me to switch models as Codex quota is consumed."""

import json
import base64
import os
import queue
import shutil
import subprocess
import sys
import threading
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
]
MODEL_EMOJIS = {"Astra": "✨", "Sol": "☀️", "Luna": "🌙"}
ORIGINAL_BANDS = [
    (100, 87.5),
    (87.5, 75),
    (75, 62.5),
    (62.5, 50),
    (50, 37.5),
    (37.5, 25),
    (25, 50 / 3),
    (50 / 3, 25 / 3),
    (25 / 3, 0),
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
CODEX = os.environ.get("CODEX_BIN") or shutil.which("codex") or str(
    Path.home() / ".local/bin/codex"
)


def read_rate_limits() -> dict[str, object]:
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
    messages: queue.Queue[str] = queue.Queue()

    def read_stdout() -> None:
        for line in process.stdout:
            messages.put(line)

    threading.Thread(target=read_stdout, daemon=True).start()

    def send(message: dict[str, object]) -> None:
        process.stdin.write(json.dumps(message) + "\n")
        process.stdin.flush()

    def receive(response_id: int, deadline: float) -> dict[str, object]:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise RuntimeError(
                    f"app-server returned no response for request {response_id}"
                )
            try:
                message = json.loads(messages.get(timeout=remaining))
            except queue.Empty as error:
                raise RuntimeError(
                    f"app-server returned no response for request {response_id}"
                ) from error
            if message.get("id") == response_id:
                return message

    try:
        deadline = time.monotonic() + 4
        send(
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
            }
        )
        receive(1, deadline)
        send({"method": "initialized", "params": {}})
        send({"method": "account/rateLimits/read", "id": 2})
        return receive(2, deadline)["result"]
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


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
            return display_model(model, mode), high
    if remaining <= FALLBACK[-1][1]:
        mode, high, _, model = FALLBACK[-1]
        return display_model(model, mode), high
    return None


def display_model(model: str, mode: str) -> str:
    family = model.split(maxsplit=1)[0]
    label = f"{model} {MODEL_EMOJIS[family]}"
    return f"{label} (fast)" if mode == "Fast" else label


def notify(message: str) -> None:
    if sys.platform == "darwin":
        escaped = message.replace("\\", "\\\\").replace('"', '\\"')
        command = [
            "/usr/bin/osascript",
            "-e",
            f'display notification "{escaped}" with title "Codex model reminder"',
        ]
    elif sys.platform == "win32":
        escaped = message.replace("'", "''")
        script = (
            "$ErrorActionPreference = 'Stop'; "
            "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null; "
            "[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null; "
            "$xml = [Windows.Data.Xml.Dom.XmlDocument]::new(); "
            "$xml.LoadXml('<toast><visual><binding template=\"ToastGeneric\"><text>Codex model reminder</text><text /></binding></visual></toast>'); "
            f"$xml.GetElementsByTagName('text').Item(1).InnerText = '{escaped}'; "
            "$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('OpenAI.Codex_2p2nqsd0c76g0!App'); "
            "if ($notifier.Setting -ne 'Enabled') { throw ('Notifications: ' + $notifier.Setting) }; "
            "$notifier.Show([Windows.UI.Notifications.ToastNotification]::new($xml))"
        )
        subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-NonInteractive",
                "-WindowStyle",
                "Hidden",
                "-EncodedCommand",
                base64.b64encode(script.encode('utf-16le')).decode('ascii'),
            ],
            creationflags=subprocess.CREATE_NO_WINDOW,
            check=True,
            capture_output=True,
            timeout=5,
        )
        return
    else:
        command = ["/usr/bin/notify-send", "Codex model reminder", message]
    subprocess.run(
        command,
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
        self.assertEqual(FALLBACK[8][2], 50)
        self.assertEqual(FALLBACK[9][1], 50)
        self.assertEqual(FALLBACK[0][1], 100)
        self.assertEqual(FALLBACK[-1][2], 0)

    def test_luna_stays_in_each_half_bottom_quarter(self) -> None:
        self.assertEqual((FALLBACK[6][1], FALLBACK[8][2]), (62.5, 50.0))
        self.assertEqual((FALLBACK[15][1], FALLBACK[17][2]), (12.5, 0.0))

    def test_scaled_band_widths(self) -> None:
        fast_widths = [high - low for _, high, low, _ in FALLBACK[:6]]
        fast_luna_widths = [high - low for _, high, low, _ in FALLBACK[6:9]]
        standard_widths = [high - low for _, high, low, _ in FALLBACK[9:15]]
        standard_luna_widths = [high - low for _, high, low, _ in FALLBACK[15:]]
        self.assertEqual(fast_widths, [6.25] * 6)
        self.assertEqual(standard_widths, [6.25] * 6)
        for widths in (fast_luna_widths, standard_luna_widths):
            self.assertEqual(len(widths), 3)
            for width in widths:
                self.assertAlmostEqual(width, 12.5 / 3, places=5)

    def test_transition_targets(self) -> None:
        self.assertIsNone(target_model(100))
        self.assertEqual(target_model(93.75), ("Astra xhigh ✨ (fast)", 93.75))
        self.assertEqual(target_model(62.5), ("Luna max 🌙 (fast)", 62.5))
        self.assertEqual(target_model(50), ("Astra max ✨", 50.0))
        self.assertEqual(target_model(12.5), ("Luna max 🌙", 12.5))
        self.assertEqual(target_model(58.333333), ("Luna xhigh 🌙 (fast)", 58.333333))
        self.assertEqual(target_model(54.166667), ("Luna high 🌙 (fast)", 54.166667))
        self.assertEqual(target_model(8.333333), ("Luna xhigh 🌙", 8.333333))
        self.assertEqual(target_model(4.166667), ("Luna high 🌙", 4.166667))
        self.assertEqual(target_model(0), ("Luna high 🌙", 4.166667))

    def test_sol_gets_a_sun_emoji(self) -> None:
        self.assertEqual(display_model("Sol medium", "Standard"), "Sol medium ☀️")

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
