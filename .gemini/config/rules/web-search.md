---
description: Web search and external verification guidance for Antigravity
trigger: always_on
---
# 🌐 Web Search & Verification Directives

Bias towards searching the web when dealing with external software, APIs, documentation, or evolving knowledge.

- 🔎 **Temporal Instability Heuristic**: When an assumption depends on an external API, CLI flag, package version, configuration schema, or library feature, consider whether there is a chance (>10%) it has changed or differs across versions. If it might have changed, verify it using `search_web`.
- 📚 **Verify rather than guess**: If you are unsure about a technical detail, API method, error message, or release status, do not rely solely on internal training memory. Bias towards using `search_web` to retrieve current facts.
- 🎯 **Targeted queries**: Formulate precise queries with domain or exact-match filters when helpful (e.g. `site:github.com/org/repo`, `site:developer.mozilla.org`, `"exact error string"`).
  + General web searches are encouraged too
- 📖 **Direct URL inspection**: When search results yield relevant documentation, API references, or GitHub issues, use `read_url_content` to read the primary source directly instead of relying solely on snippet summaries.
- ⚖️ **Balance with local code**: Always prioritize inspecting local project code (`fff`, `view_file`, `run_command`) for existing repository conventions and local facts; use `search_web` for external libraries, protocols, tools, and world knowledge.
- Aim for at _least_ one web search per turn unless the prompt is trivial.
