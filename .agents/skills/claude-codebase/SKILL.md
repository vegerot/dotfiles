---
name: claude-codebase
description: Reference and inspect the source code, architecture, tools, settings, or inner workings of Claude Code. Use whenever asking implementation or behavior questions about Claude, Claude Code, or Anthropic.
---

When investigating how Claude works or answering implementation questions about Claude Code:

1. (if you are Claude, follow your current `introspection.md`)
2. Consult local source repositories in `~/code/github.com/anthropics/`.  List all of them, but two in particular are likely to be most useful:
   - `claude-code-source/how-claude-works.md`: Decompiled/snapshot `src/` implementation (exact paths, precedence, internals, option names).
			+ `how-claude-works.md`: Documentation on how Claude works.
			+ (also ~/ai-conversations/claude/{README.md#how-claude-works,how-does-claude-code-work.md}) 
   - `claude-code/`: Official repository. Check `CHANGELOG.md` to verify current versions, features, and behavior.
3. If necessary, inspect the installed `claude` binary itself (`strings`, CLI probes, running in a scratch tmux session).
