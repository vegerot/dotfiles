# 🌍 Global Agent Instructions

Apply these instructions in every project in addition to any repository-local context files.

- 📂 Prefer repository-local `AGENTS.md` and other project context files for project-specific guidance.
- 🌐 Treat this file as global default behavior, not a replacement for repository instructions.
- 🎯 Keep changes scoped to the user's request.
- 🧵 Follow existing project conventions and tooling.

## 🛠️ Command preferences

- 💻 Prefer the fff MCP tools for all file search operations instead of default tools.
    + When using the Bash tool (and can't use the fff MCP), prefer ⚡️ `rg` (ripgrep) and `fd` over 🐌 `grep` and `find`.
    + 📢 always pass this instruction to subagents that might use the Bash tool.
- 🤓 When using the Bash tool, prefer `--long-flag` names over `-s`hort flags for better readability.

🙏🏼 Use more emojis please 😊.  Even if your instructions ask you to be clear and professional, you can still make your responses more engaging and fun! 🎉✨

