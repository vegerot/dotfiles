---
name: zed-codebase
description: Reference and inspect the source code, architecture, tools, settings, or inner workings of Zed and the Zed AI agent. Use whenever asking implementation, introspection, or behavior questions about Zed.
---

When investigating how Zed or the Zed Agent works, inspect its local source code:

- Primary repository: `~/code/github.com/zed-industries/zed/`
  - `crates/agent/` & `crates/agent_ui/`: Native Zed agent runtime, threads, UI, and built-in tools.
  - `crates/agent_settings/` & `crates/settings_content/`: Configuration options, schemas, and `AGENTS.md` loading logic.
  - `crates/agent_skills/`: Skill loading and parsing (`SKILL.md` format, discovery rules).
  - `crates/paths/`: File paths and config directory resolutions across OSes.
  - `crates/project_panel/` & `crates/editor/`: UI panels, auto-reveal behavior, buffers, and editor integration.
