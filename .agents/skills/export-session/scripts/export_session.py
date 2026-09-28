#!/usr/bin/env python3
"""Render the user and assistant messages in a Codex rollout JSONL file as Markdown."""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Rollout:
    path: Path
    metadata: dict[str, Any]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rollout", type=Path, help="Rollout JSONL file to export")
    parser.add_argument(
        "--cwd",
        type=Path,
        default=Path.cwd(),
        help="Workspace used to find the most recent rollout (default: current directory)",
    )
    parser.add_argument("--output", type=Path, help="Markdown output path")
    return parser.parse_args()


def codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))


def read_metadata(path: Path) -> dict[str, Any] | None:
    try:
        with path.open(encoding="utf-8") as rollout:
            for raw_line in rollout:
                line = json.loads(raw_line)
                if line.get("type") == "session_meta":
                    payload = line.get("payload")
                    return payload if isinstance(payload, dict) else None
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None
    return None


def select_rollout(cwd: Path) -> Rollout:
    sessions_dir = codex_home() / "sessions"
    if not sessions_dir.is_dir():
        raise ValueError(f"Codex sessions directory does not exist: {sessions_dir}")

    target_cwd = cwd.resolve()
    matches: list[Rollout] = []
    for path in sessions_dir.rglob("rollout-*.jsonl"):
        metadata = read_metadata(path)
        if metadata is None:
            continue
        recorded_cwd = metadata.get("cwd")
        if not isinstance(recorded_cwd, str):
            continue
        try:
            if Path(recorded_cwd).resolve() == target_cwd:
                matches.append(Rollout(path, metadata))
        except OSError:
            continue

    if not matches:
        raise ValueError(
            f"No Codex rollout was found for {target_cwd}. Run /rollout and retry with --rollout."
        )
    return max(matches, key=lambda rollout: rollout.path.stat().st_mtime)


def message_from_line(line: dict[str, Any]) -> tuple[str, str] | None:
    item_type = line.get("type")
    payload = line.get("payload")
    if not isinstance(payload, dict):
        return None

    if item_type == "event_msg":
        event_type = payload.get("type")
        text = payload.get("message")
        if event_type == "user_message" and isinstance(text, str):
            return ("User", text)
        if event_type == "agent_message" and isinstance(text, str):
            return ("Assistant", text)
        return None

    if item_type != "response_item":
        return None
    response_type = payload.get("type")
    if response_type == "agent_message" and isinstance(payload.get("message"), str):
        return ("Assistant", payload["message"])
    if response_type != "message":
        return None

    role = payload.get("role")
    if role not in {"user", "assistant"}:
        return None
    content = payload.get("content")
    if not isinstance(content, list):
        return None
    text = "\n".join(
        item["text"]
        for item in content
        if isinstance(item, dict)
        and item.get("type") in {"input_text", "output_text"}
        and isinstance(item.get("text"), str)
    )
    return ({"user": "User", "assistant": "Assistant"}[role], text) if text else None


def transcript(rollout: Rollout) -> list[tuple[str, str]]:
    messages: list[tuple[str, str]] = []
    with rollout.path.open(encoding="utf-8") as source:
        for raw_line in source:
            try:
                message = message_from_line(json.loads(raw_line))
            except json.JSONDecodeError:
                continue
            if message is not None and message != (messages[-1] if messages else None):
                messages.append(message)
    return messages


def render(rollout: Rollout, messages: list[tuple[str, str]]) -> str:
    metadata = rollout.metadata
    session_id = metadata.get("session_id") or metadata.get("id") or rollout.path.stem
    lines = [
        "---",
        f"Session ID: {session_id}",
        f"Source rollout: {rollout.path}",
        f"Workspace: {metadata.get('cwd', 'unknown')}",
        f"Exported by: {Path(__file__).name}",
        "---",
        "",
        "# Codex session transcript",
        "",
    ]
    for role, text in messages:
        lines.extend((f"## {role}", "", text.rstrip(), ""))
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    args = parse_args()
    if args.rollout:
        rollout_path = args.rollout.expanduser().resolve()
        metadata = read_metadata(rollout_path)
        if metadata is None:
            raise ValueError(f"Not a readable Codex rollout JSONL file: {rollout_path}")
        rollout = Rollout(rollout_path, metadata)
    else:
        rollout = select_rollout(args.cwd.expanduser())

    session_id = str(rollout.metadata.get("session_id") or rollout.metadata.get("id") or "session")
    output = args.output or (args.cwd / f"codex-session-{session_id}.md")
    output = output.expanduser().resolve()
    if output.exists():
        raise ValueError(f"Output already exists: {output}. Choose --output with a new path.")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(rollout, transcript(rollout)), encoding="utf-8")
    print(f"Rollout: {rollout.path}")
    print(f"Exported: {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
