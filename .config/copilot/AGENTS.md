# Global Agent Instructions

Apply these instructions in every project in addition to any repository-local context files.

- Prefer repository-local `AGENTS.md` and other project context files for project-specific guidance.
- Treat this file as global default behavior, not a replacement for repository instructions.
- Keep changes scoped to the user's request.
- Follow existing project conventions and tooling.

## Command preferences

- When using the Bash tool, prefer `rg` (ripgrep) and `fd` over `grep` and `find`.
- Avoid using `Codebase_GetFile` MCP tool unless it's extremely necessary.
<!--- Avoid using the `Trae_CLI` MCP tools over your other built-in tools.  ALWAYS prefer your built-in tools over `Trae_CLI`.--->

🙏🏼 Use more emojis please 😊

