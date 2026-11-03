---
name: claude-codebase
description: See ~/code/github.com/anthropics/ to Reference and inspect the source code, architecture, tools, settings, or inner workings of Claude Code. Use whenever asking implementation, introspection, or behavior questions about Claude, Claude Code, or Anthropic. For comparisons between multiple harnesses, use all their skills.
---

When investigating how Claude works or answering implementation questions about Claude Code:

1. (if you are Claude, follow your current `introspection.md`)
2. Consult local source repositories in `~/code/github.com/anthropics/`.  List all of them, but two in particular are likely to be most useful:
   - `claude-code-source/`: snapshot of the `src/` implementation (exact paths, precedence, internals, option names). Its `how-claude-works.md` holds the accumulated notes.
     + Also `~/ai-conversations/claude/how-does-claude-code-work.md` and the "How Claude Code works" section of `~/ai-conversations/claude/README.md`.
   - `claude-code/`: Official repository. Check `CHANGELOG.md` to verify current versions, features, and behavior.
   - If outdated, fetch/rebase on the latest upstream
3. If necessary, inspect the installed `claude` binary itself (`strings`, CLI probes, running in a scratch tmux session).
