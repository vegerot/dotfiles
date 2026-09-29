#!/usr/bin/env python3
"""Remind me to compact after a Codex request exceeds 272K input tokens."""

import base64
import json
import mmap
import os
import subprocess
import sys
from pathlib import Path


LIMIT = 272_000
STATE_DIR = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "context-reminder"


def latest_input_tokens(transcript_path: str) -> int | None:
    with open(transcript_path, "rb") as transcript:
        if transcript.seek(0, 2) == 0:
            return None
        with mmap.mmap(transcript.fileno(), 0, access=mmap.ACCESS_READ) as data:
            end = len(data)
            while end:
                start = data.rfind(b"\n", 0, end - 1) + 1
                line = data[start:end]
                if b'"type":"token_usage_record"' in line:
                    return json.loads(line)["payload"]["usage"]["input_tokens"]
                end = start - 1
    return None


def notify(input_tokens: int) -> None:
    message = f"Latest request used {input_tokens:,} input tokens. Consider /compact."
    if sys.platform == "darwin":
        command = [
            "/usr/bin/osascript",
            "-e",
            f'display notification "{message}" with title "Codex context reminder"',
        ]
    elif sys.platform == "win32":
        escaped = message.replace("'", "''")
        script = (
            "$ErrorActionPreference = 'Stop'; "
            "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null; "
            "[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null; "
            "$xml = [Windows.Data.Xml.Dom.XmlDocument]::new(); "
            "$xml.LoadXml('<toast><visual><binding template=\"ToastGeneric\"><text>Codex context reminder</text><text /></binding></visual></toast>'); "
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
                base64.b64encode(script.encode("utf-16le")).decode("ascii"),
            ],
            creationflags=subprocess.CREATE_NO_WINDOW,
            check=True,
            capture_output=True,
            timeout=5,
        )
        return
    else:
        command = ["/usr/bin/notify-send", "Codex context reminder", message]
    subprocess.run(
        command,
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=1,
    )


def main() -> None:
    hook = json.load(sys.stdin)
    if hook.get("agent_id"):
        return
    transcript_path = hook.get("transcript_path")
    if not transcript_path:
        return
    input_tokens = latest_input_tokens(transcript_path)
    if input_tokens is None:
        return

    marker = STATE_DIR / hook["session_id"]
    if input_tokens <= LIMIT:
        marker.unlink(missing_ok=True)
        return

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        marker.touch(exist_ok=False)
    except FileExistsError:
        return
    notify(input_tokens)


if __name__ == "__main__":
    main()
