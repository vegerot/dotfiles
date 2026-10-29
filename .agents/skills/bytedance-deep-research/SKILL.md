---
name: bytedance-deep-research
description: Deep investigation of ByteDance or TikTok infrastructure, code, conventions, docs, and operational history using local checkouts, bytedcli, Lark CLI, and One Context. Use for deep dives, cross-system architecture or mechanisms, incident reconstruction, conflicting sources, or consequential claims needing substantial verification. Use bytedance-or-tiktok for quick orientation and routine lookups. 
---

# ByteDance deep research

Own the research and synthesis. Use local source, direct CLI/API queries, and retrieval services. Consult a specialist agent for a specific missing corpus or integration, or when the user explicitly requests it.

Assume One Context is already installed, configured, and authorized. Use it directly; do not start with installation, login, or authentication-status checks.

This skill should generally be ran in a subagent or after running this skill invoke subagent(s) to do the research.

## Research workflow

Choose the first evidence source by the question:

| Question | First source |
| --- | --- |
| Unfamiliar internal term, policy, owner, or context spanning teams/docs/chats | Configured One Context; expand into its cited sources |
| Exact implementation, parsing, defaults, or repository conventions | Relevant local checkout and its instructions; use Codebase when not cloned |
| Current deployment, configuration, permissions, tickets, metrics, or traces | Relevant platform API/CLI in the target environment |
| History, incidents, decisions, or team knowledge | One Context and source records; select the known knowledge space when supplied |

Combine these routes when the question spans evidence types. Do not substitute
keyword-only search for enterprise-context discovery merely because it is
familiar. Use Lark/Insearch to expand or verify source results, and reformulate
queries or resolve names before concluding that a source has no evidence.

1. **Identify the evidence needed.** Separate current runtime behavior, source
   implementation, documented intent, and historical context. Start with the
   question's repository, service, error, acronym, or URL. Form a few concrete
   subquestions when the task spans systems.
   For definitions or comparisons, identify important variants before mapping
   relationships. For identity/auth questions, distinguish the subject, issuer,
   credential type, exchange, and permission decision. A detailed client path
   must not substitute for coverage of the broader question.
2. **Use relevant local context.** For a known repository, read its `AGENTS.md`
   files and project records before investigating implementation. When locating
   tool source, use `command -v` and resolve executable symlinks to find checkouts.
   Search known repository roots narrowly. Prefer `rg` for
   shell searches, use readable long flags, and pass these search conventions to
   subagents. Do not scan the entire home directory to discover repositories.
3. **Choose the source interface.** Read [tools.md](references/tools.md) for command
   examples, domain routing, and retrieval versus chat distinctions. For a
   specialized bytedcli command, locate its bundled domain manual, usually
   `skills/bytedance-<domain>/SKILL.md`, and read the relevant reference. Use
   actual filenames; do not assume a fixed manual count or naming pattern.
   Check the installed command's help when flags are uncertain; inspect the local
   wrapper when behavior or endpoint selection matters. Batch independent reads
   and searches, then follow promising results sequentially.
4. **Retrieve evidence and follow it.** Search exact identifiers, aliases, and
   Chinese/English terminology when useful. Fetch the source documents, relevant
   code, or messages behind results. Follow citations and related services until
   the mechanism is clear. Consume returned pages and content bundles where
   relevant; do not mistake a search snippet for the full source.
5. **Cross-check consequential claims.** Compare documentation with code or live
   platform data. Record the branch/commit, environment/region, and time when they
   affect the conclusion; also retain the knowledge-space/dataset identity and
   filters when they change the evidence. Treat generated Wiki content and
   indexed knowledge as
   potentially behind the checkout. Explain conflicts instead of silently
   selecting a convenient source.
   Preserve a rule's scope and documented exceptions. Separate required policy
   from implemented behavior; one compliant example does not prove uniform
   compliance across a platform or repository.
6. **Resolve access gaps proportionately.** Distinguish missing OAuth scope,
   expired login, resource permission, absent index, and absent interface.
   Continue independent research while required authorization is pending. Report
   the unresolved coverage limit; a login failure does not prove another agent
   has exclusive data. Do not expose tokens or borrow another service's identity.
7. **Answer from the evidence.** Lead with the result and explain the mechanism in
   plain language. Cite source URLs or local file lines beside consequential
   claims, with the actual section, message ID/time, or fragment locator when
   available. A plausible title or rendered citation alone is not verification.
   Distinguish observed facts, documented claims, inferences, and unknowns.
   Check every requested element before finalizing; disclose an important
   unresolved variant rather than hiding it behind a detailed partial answer.
   Use a diagram when a call path or layering is easier to understand visually.
   Stop when the evidence answers the question; retain useful findings in the
   appropriate project record when the task warrants it.

## Retrieval and specialist agents

- Use direct Lark, Codebase, CodeVision, DeepWiki snippets, platform APIs, and
  One Context sources when available. A semantic index is useful infrastructure,
  not a reason to delegate the final answer to another agent.
- Use the configured `one-context` CLI/skill for enterprise context, knowledge
  topics, code discovery, and ingested history. Load its installed `SKILL.md` and
  invoke its `scripts/run-cli.sh` or PowerShell wrapper. Follow its current retrieval
  contract and content-reading instructions. Investigate authorization only if
  an actual request fails; report the specific access gap rather than restarting
  setup or assuming identical corpus coverage.
- Use ordinary research subagents to investigate independent local modules or
  source sets when useful. Give each a bounded question and request citations.
- Consult Mira, an AIME space, BitsAI, Tika, or another specialist when it adds a
  relevant corpus/integration unavailable directly. Before consulting, identify
  that corpus/integration and record what establishes the gap: unavailable direct
  interface, specific resource authorization denial, or documented coverage
  difference. A difficult question, empty search, or vague capability claim is
  insufficient. Try the relevant direct route, alternate terms/source filters,
  and source links before treating retrieval as exhausted. Explain the gap, send
  a focused question, request source links, and verify important findings.
  Follow explicit user requests to consult these agents.
- Treat capability interviews as leads. Do not accept unsupported replacement
  percentages, privileged-access claims, or assertions that only that agent can
  plan searches or synthesize evidence.
- Recognize that an MCP tool can wrap a conversational agent. BitsAI's documented
  `ask` integration and `insearch --source bitsai.bytedance.net` still create Q&A
  conversations. DeepWiki's default `summary` mode generates an answer; choose
  `--format snippets` to consume indexed chunks directly.
- Recover existing session output/history after a timeout or incomplete chat
  response before creating another conversation. Preserve the distinction
  between agent output, source references, and actual tool execution evidence.
  A completion flag or opening update does not establish a substantive answer;
  read the full final result and its references before using it.

Compare source coverage and permissions rather than assuming all products are
identical. Shared or imported knowledge corpora can differ from live source
access. CLI chat wrappers can hide tool/citation events and add latency; quick
mode alone does not establish disabled reasoning or the same execution path as
the local agent.

Keep research within the requested scope. Read-only investigation does not
authorize production mutations, index builds, messages to people, or installing
history-upload hooks. Apply the user's existing authorization when related work
is explicitly requested.
