---
name: context-deep
description: A deeper, exact version of the built-in `/context` command — reports precise token counts and dollar cost for the CURRENT Claude Code conversation by default (or any other session's transcript), broken down by model, tool, day, and attachment type, plus exact image-token math. Use whenever the user asks for a more detailed context/token breakdown than `/context` gives, asks how many tokens THIS conversation or session has used, what it cost, which tool or model is burning the most tokens, or why context usage is high — even if they just say things like "give me a deeper context breakdown," "how much has this conversation cost," or "what's eating my context window." Also works on other Claude Code transcripts if a path or session is named explicitly. Claude-Code transcripts only (not Codex/Trae/opencode — different JSONL schema).
---

# context-deep

A CLI (`transcript-usage`, symlinked into `~/.local/bin/`) that parses Claude Code session
transcripts and prints an exact token/cost report — think "`/context`, but with the receipts."
Source of truth for the script itself:
`~/code/github.com/vegerot/coding-model-router/tools/transcript-usage.ts` (a Bun script — edit it
there, the symlink just makes it reachable on `PATH`).

Reach for this instead of eyeballing a `/context` screenshot or guessing from message count — the
transcript stores the real `usage` block on every API response, so this is exact, not estimated,
for everything except the "Live Context Composition" section (see below).

## Default target: THIS conversation

Unless the user names a different session or points at a specific file, run it against **the
transcript of the conversation you're in right now**:

1. Read the `CLAUDE_CODE_SESSION_ID` environment variable — it's set for every Claude Code
   session (verify with `echo $CLAUDE_CODE_SESSION_ID`).
2. Find that session's file: `~/.claude/projects/**/<session-id>.jsonl` (one match — the sanitized
   cwd directory it lives under doesn't matter, so don't bother computing it by hand).
3. Run `transcript-usage` on that path.

```bash
transcript-usage "$(fd --type f "${CLAUDE_CODE_SESSION_ID}.jsonl" ~/.claude/projects)"
```

**If `CLAUDE_CODE_SESSION_ID` is unset** (older Claude Code version, or some other harness),
fall back to the most-recently-modified `.jsonl` under
`~/.claude/projects/<cwd-with-non-alphanumerics-as-dashes>/` — but say you're using a heuristic,
since a stale or wrong match is possible if multiple sessions in that directory were active
recently.

**The report reflects the transcript as saved up to your last completed turn** — it can't see the
in-flight turn that's still generating, so the numbers are always very slightly behind "right
now." That's fine for this use case and not worth flagging unless the user asks about a specific
just-sent message.

## Other targets

If the user names a different session, a project, or "all my sessions," resolve that instead:

- **"This project"** → glob `~/.claude/projects/<sanitized-cwd>/*.jsonl` for every session run in
  the current repo.
- **A specific session id or path** → use it directly.
- **Multiple files** → pass them all; the tool merges them into one combined report.

## Running it

```
transcript-usage <transcript.jsonl>... [--json]
```

`--json` prints the same data as structured JSON instead of the text table — use it when you need
to compute on the numbers rather than just read them.

**A bad path throws an unhandled `ENOENT` with a full stack trace, not a clean error message.**
Check the file exists before running, or the user will see a Bun crash dump instead of an answer.

## Reading the report

- **Header:** file(s), session id(s), Claude Code version(s) seen, time window, message count,
  total estimated spend.
- **Token lines:** prompt/cache-read/cache-write/output/thinking tokens, cache hit rate, and
  `prompt:completion` ratio — cache-heavy sessions (steady long conversations) will show cache%
  near 100.
- **By Model / By Effort / By Day:** grouped tables of tokens, messages, and spend, each cell
  with an `(x%)` share of that table's total — this is the fastest way to answer "which
  model/day is costing the most."
- **Live Context Composition:** reconstructs the *live* conversation (the `parentUuid` chain
  ending at the last assistant message) and estimates each block the way Claude Code's own
  `/context` command does. This section is an **estimate** (4 bytes/token for text), not exact —
  say so if the user is relying on it for a precise number. The gap between "actual context" and
  "estimated messages" is the system prompt, tool definitions, memory files, and skills, which the
  transcript doesn't store directly. This is the section that makes this skill "`/context` but
  deeper" — it's the same shape as the built-in command's output, just computed from the
  transcript instead of live.
- **By Tool:** calls, call tokens, and result tokens per tool name, across the *whole* transcript
  (not just the live chain) — this is what answers "which tool is burning my tokens."
- **By Attachment Type:** tokens by injected-content type (`skill_listing`,
  `deferred_tools_delta`, `edited_text_file`, `async_hook_response`, etc.) — useful for "why is my
  context so full" beyond just tool calls.
- **Images** are priced exactly via the real Anthropic vision patch formula (parsed dimensions +
  official downscale rule + `⌈w/28⌉×⌈h/28⌉` patches), not estimated, whenever the transcript has
  full base64 image data to read.
- **Thinking tokens are billed but stored empty** in the transcript — the report notes this; don't
  read a `0` in the Live Context Composition thinking row as meaning thinking was free.

## Caveats to pass on to the user

- **Claude Code transcripts only.** Codex, Trae CLI, and opencode store sessions in a different
  JSONL shape (`response_item`/`session_meta` events, not `type: "user"`/`"assistant"` with a
  `message` field) — pointing this tool at one of those silently undercounts rather than erroring.
- **Spend uses a hardcoded price table** in the script (`$`/million tokens, with cache-write/read
  multipliers), not a live pricing lookup — it can drift if Anthropic's list prices change and the
  table isn't updated.
- **Duplicate-line dedup matters.** Claude Code writes one JSONL line per content block, repeating
  the same `message.usage` on every line for one API response. The tool dedupes by `message.id`;
  if you ever see a report that looks ~2× too high, that's the symptom of a version that isn't
  deduping correctly.
