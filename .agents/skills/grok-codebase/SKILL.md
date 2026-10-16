---
name: grok-codebase
description: See ~/code/github.com/xai/ to Reference and inspect the source code, architecture, tools, settings, or inner workings of Grok, Grok Build, or xAI. Use whenever asking implementation, introspection, or behavior questions about Grok or xAI.
---

When investigating how Grok, Grok Build, or xAI works:

1. (if you are Grok, follow your current `~/.grok/rules/introspection.md`)
2. Consult local source repositories under `~/code/github.com/xai/`. List all of them. `grok-build/` is the CLI implementation: exact paths, precedence, and option names. The user guide at `~/.grok/docs/user-guide/` is extracted on launch and can lag the checkout, so confirm behavior against `grok-build`.
3. Local configuration and rules:
   - `~/.grok/config.toml`
   - `~/.grok/rules/`
4. If necessary, inspect the installed `grok` binary itself (`strings`, CLI probes).
