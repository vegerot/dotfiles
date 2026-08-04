---
name: coco-export-location
description: ONLY to be used by the TraeCLI or Coco agents.  Do not use if you are another agent.  Tells you where coco/TraeCLI writes the exported conversation transcript after the user runs the /export slash command. Use this when the user asks "where did my export go", "where is the exported conversation/transcript", "where does /export save", "find my exported chat", or wants to locate, open, read, or share a conversation.md file produced by /export.
---

# Coco /export Location

When a user runs the `/export` slash command in coco/TraeCLI, the conversation
transcript is rendered to a human-readable Markdown file inside the **current
session's own directory** under the user cache dir.  The user just ran `/export` on _this conversation_ and your job is to find the transcript from that conversation.

## Where the export goes

```
<user-cache-dir>/coco/sessions/<session-id>/conversation.md
```

Resolve `<user-cache-dir>` per platform (Go `os.UserCacheDir`):

| Platform | Path |
| --- | --- |
| macOS | `~/Library/Caches/coco/sessions/<session-id>/conversation.md` |
| Linux | `$XDG_CACHE_HOME/coco/sessions/<session-id>/conversation.md` (defaults to `~/.cache/coco/...`) |
| Windows | `%LocalAppData%\coco\sessions\<session-id>\conversation.md` |

`<session-id>` is the active session UUID. The exported file always records its
own absolute path in the header, e.g.:

```
---
Exported at: 2026-05-13T18:28:13-07:00
Exported to: /Users/you/Library/Caches/coco/sessions/<session-id>/conversation.md
Version: 0.120.31
Session ID: <session-id>
Model: ...
---
```

## How to find it

1. If the session ID is known, go straight to the path above.
2. Otherwise, locate the most recent export:
   - macOS: `fd --type f --glob conversation.md ~/Library/Caches/coco/sessions -X ls -t | head -1`
   - Linux: `fd --type f --glob conversation.md "${XDG_CACHE_HOME:-$HOME/.cache}/coco/sessions" -X ls -t | head -1`
3. Read the `Exported to:` line in the file header to confirm the canonical path.
4. Quickly grep for a few lines of the conversation to confirm it's the right file.

## Important distinctions

- `/export` produces the **Markdown** `conversation.md`. The same session
  directory also holds raw machine data (`events.jsonl`, `traces.jsonl`,
  `session.json`, `session.log`) — those are NOT the `/export` output.
- The separate "Export session data and upload to administrator" / "Share
  session" feature **uploads** data and does not write a local transcript. Do
  not point users there when they ask about `/export`.

Now, go and find the transcript for _this conversation_.
