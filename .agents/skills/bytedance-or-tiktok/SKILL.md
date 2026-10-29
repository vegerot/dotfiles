---
name: bytedance-or-tiktok
description: Quick orientation and lightweight lookups for ByteDance or TikTok jargon, internal tools, services, docs, ownership, and repository conventions. Use to learn enough context for the immediate task. 
---
# ByteDance / TikTok orientation

Learn enough to proceed. Use one or two focused lookups in the main agent and answer briefly; stop when reliable evidence answers the question.

Assume bytedcli, Lark CLI, and One Context are configured. Check authentication only after an actual access error.

| Need | Start with |
| --- | --- |
| Jargon | `bytedcli lark lingo`; One Context for additional context |
| Internal facts, policies, owners, or prior discussions | One Context and its cited sources |
| Tool or platform overview | Official Lark/ByteCloud docs or the matching bytedcli domain manual |
| Code or repository conventions | Local checkout and `AGENTS.md`; Codebase if not cloned |
| Current configuration or operational state | Relevant platform API/CLI in the target site and region |

Read and cite the relevant passage. Verify unfamiliar flags with installed help, respect site/region differences, and use One Context's installed wrapper. Label uncertainty and avoid routine Mira/AIME/Tika delegation.

Use `$bytedance-deep-research` for deep dives, cross-system mechanisms, incident reconstruction, conflicting sources, or consequential claims needing substantial verification. Give a bounded research subagent the question, known facts, source links, and unresolved gap. 
