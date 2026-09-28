---
name: export-session
description: Export a local Codex CLI conversation from its rollout JSONL file to a readable Markdown transcript. Use when the user asks to export, save, share, archive, or locate a Codex session transcript, including requests such as "export this conversation" or "$export-session".
---

# Export Codex Session

Run the bundled exporter to locate the newest Codex rollout whose recorded working directory matches the current workspace and render its user and assistant messages as Markdown.

```bash
python3 <skill-dir>/scripts/export_session.py --cwd "$PWD"
```

The script writes `codex-session-<session-id>.md` in the current workspace, prints both the rollout and output paths, and refuses to overwrite an existing export.

## Exact-session export

The automatic lookup is a best effort. When several Codex sessions share a workspace or the user requires an exact session, ask them to run `/rollout`, then pass the reported path explicitly:

```bash
python3 <skill-dir>/scripts/export_session.py --rollout /absolute/path/to/rollout.jsonl --output /desired/path/conversation.md
```

Do not upload or publish the transcript. Treat it as potentially sensitive local data. Report the selected rollout and generated Markdown path after a successful export.
