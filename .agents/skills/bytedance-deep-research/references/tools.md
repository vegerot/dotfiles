# Direct research tools

Checked against local bytedcli 0.180.0 and Mira sources on 2026-10-28. Treat command
examples as starting points; verify installed help when the contract matters.

- [Source selection](#source-selection)
- [Checkouts, manuals, and global flags](#find-tools-and-checkouts)
- [Lark and Insearch](#lark-and-insearch)
- [Framework documentation](#framework-documentation)
- [Code and live platforms](#code-and-live-platforms)
- [Ownership, standards, tickets, configuration, and data](#domain-command-playbook)
- [One Context](#one-context)
- [Specialist interfaces](#specialist-interfaces)

## Source selection

| Question or evidence | Start with | Relevant limit |
| --- | --- | --- |
| Exact implementation, configuration parsing, defaults | Local checkout; Codebase search/file | Identify the revision; remote text indexes can lag |
| Unknown internal term, doc, owner, prior discussion | Lark search/Lingo; Insearch; One Context | Check source coverage and resource permissions |
| Semantic code discovery or relationships | CodeVision; DeepWiki snippets; One Context code sources | Indexed/generated knowledge may be stale |
| Current deployments, config, APIs, ownership, tickets | Relevant bytedcli platform command | Verify site, region, identity, and resource access |
| Logs, metrics, traces | `bytedcli argos tool`; APM/log commands | The direct tool interface is separate from `argos run` |
| Meeting context or mail | Lark Minutes/note/mail; One Context | Plain document search does not cover every source |
| Maintained knowledge or ingested cross-agent history | One Context; relevant AIME space | Only authorized, actually ingested material is available |

## Find tools and checkouts

```sh
command -v bytedcli
command -v lark-cli
command -v one-context
```

On Linux, use `readlink -f` on the returned executable path. Inspect its repository
root and instructions; do not assume a packaged binary has source next to it.
Known devbox checkout locations from the investigation were:

- `~/code/code.byted.org/byteapi/bytedcli`
- `~/code/github.com/larksuite/cli` (Lark CLI Go source; bytedcli wraps its binary)
- `~/code/code.byted.org/blade/cis-mira`
- `~/code/code.byted.org/blade/open_mira`
- `~/code/code.byted.org/blade/` for related Mira gateway/model/tool services
- `~/code/code.byted.org/i18n_ecom_fe/` for TikTok Shop frontend questions

These are leads, not mandatory paths. Confirm existence and revision locally.
Search the relevant namespace or known clone, rather than enumerating every
repository. Read the matching bytedcli domain manual under `skills/`; the audited
checkout uses names such as `bytedance-cloud-docs`, `bytedance-coral`, and
`bytedance-codevision`.

Place bytedcli global flags before the domain command:

```sh
bytedcli --json --site i18n-bd --as user <domain> <command> <options>
```

Use `--jq '<expression>'` to project large JSON outputs. If shell-wrapper hints
interfere with machine-readable output, set `AGENT_SILENCE_HINTS=1` for that
invocation where the shell supports it. Do not change global shell settings.
Investigate auth status only after an actual access error, or when a requested
diagnosis concerns authentication; `bytedcli insearch status` reports several
source-specific auth states. Preserve existing user authorization when resolving
the error, and continue independent research.

Some companion commands can download/install their runtime even for `--help`
(observed for Oncall). Inspect local registrations/manuals instead when a task
requires leaving local installations unchanged.

## Lark and Insearch

```sh
bytedcli lark docs search --as user --query 'Kitex' --page-size 20
bytedcli lark docs fetch --as user --doc '<document-or-wiki-url>' --doc-format markdown
bytedcli lark im --help
bytedcli lark lingo --help
bytedcli lark minutes --help

bytedcli --json insearch query 'Kitex' \
  --source feishu.cn/drive/home,bytetech.info,cloud.bytedance.net --count 10
bytedcli --json insearch get '<source-url>'
```

Use direct Lark search pagination and filters for thorough document/message
research. The audited Insearch Lark adapters request one page, cap docs at 20 and
messages at 50, ignore offset, and discard page tokens. Raising Insearch count
does not fix this. Inspect the installed implementation before assuming the
limitation still exists.

Insearch's default sources are Lark docs/messages, ByteCloud docs, intranet, and
ByteTech. Ask Feishu and BitsAI are separate Q&A paths; they are not additional raw
document searches. `cloud-docs` searches ByteCloud's documentation platform.

`insearch get` supports source-specific document/article/code URLs and
`feishu://message/<chat-id>/<message-id>` handoff URLs returned by message search.
Read message context where necessary. An allowlisted plain-GET fallback may
return HTML or a login page; it does not guarantee clean Markdown for every URL.

For internal acronyms, use the configured One Context or the installed Lingo
commands when available. If Lingo has no typed command, use documented read
endpoints through the raw API, for example:

```sh
lark-cli api POST /open-apis/lingo/v1/entities/match \
  --as bot --data '{"word":"<term>"}'
lark-cli api POST /open-apis/lingo/v1/entities/search \
  --as bot --data '{"query":"<keyword>","page_size":10}'
```

These POST endpoints perform lookups. Use the authorized identity and verify its
scopes; `baike:entity:readonly` is a tenant/bot scope, so do not request it as a
user OAuth scope. Do not infer that all Lingo operations require bot identity.

## Framework documentation

Read `skills/bytedance-cloud-docs/SKILL.md` and its recall reference for framework
or platform manuals. The ByteCloud index links to component indexes and articles:

```sh
bytedcli insearch get \
  'https://cloud.bytedance.net/api/v1/cloud_developer/docs/all/cn/llms.txt'
bytedcli insearch get '<component-llms.txt-url-returned-by-index>'
bytedcli insearch get '<article.md-url-returned-by-component-index>'
bytedcli --json cloud-docs search --keyword '<keyword>'
bytedcli cloud-docs get '<doc-id>'
```

Select a small relevant component set; follow the returned URLs, preserving
their host, language, region, and path. Use `insearch get` for `llms.txt` and `.md`
URLs, and `cloud-docs get` for a known document ID. `bytedoc` operates the ByteDoc
Mongo/document database service; use `cloud-docs` for developer documentation.

## Code and live platforms

```sh
bytedcli --json codebase search code \
  --query 'GetBytecloudJwtToken' --repo-filter '^byteapi/bytedcli$' --limit 10
bytedcli codebase repo file src/api/mira/stream.ts \
  --repo byteapi/bytedcli --revision '<branch-or-commit>'
bytedcli --json codebase repo list --query '<keyword>' --page-size 20
bytedcli --json codebase repo get '<owner/repository>'
bytedcli --json codebase repo directory list \
  --repo '<owner/repository>' --path .
bytedcli codevision evidence --help
bytedcli --json deepwiki search \
  --repo-name '<owner/repository>' --query '<question>' --format snippets --limit 5
bytedcli deepwiki get-content --help
bytedcli aime deepwiki --help
bytedcli argos tool --help
```

Top-level DeepWiki is Aiden knowledge retrieval; `aime deepwiki` fetches generated
repository Wiki versions/files. They are distinct interfaces. DeepWiki snippets
can contain generated documents; read relevant source before asserting current
implementation. Do not use an analysis operation that auto-builds an index as a
routine read-only fallback.

For platform queries, inspect `bytedcli <platform> --help`, then narrow to the
resource read command. Choose `--site` and region flags from the user's target
environment. Avoid assuming CN results apply to TikTok or other regions.

Repository list uses `--page-size`; repository get takes a positional repository;
directory list requires `--path`. JSON file reads may return base64 at
`.data.file.Content`; decode it before reading or cite the source URL. Use `blame`,
commit, and MR reads for history when necessary. Preserve the selected revision.

For service topology, inspect `deepwiki get-service-meta`, `deepwiki
business-graph`, CodeVision repository/graph commands, and `ai-dev-pro afs` help.
These are additional source interfaces, not proof of identical index coverage.

## Domain command playbook

Use these checked command paths to locate evidence, then read the domain manual
for the actual query and environment. Syntax was checked locally; availability
and access still depend on the caller's permissions and target region.

| Evidence | Read command example |
| --- | --- |
| Service tree | `bytedcli --json bytetree search --keyword '<psm-or-keyword>' --page-size 20` |
| Service owner | `bytedcli --json bytetree owner list --node-id '<node-id-from-search>'` |
| Application metadata | `bytedcli --json app-info search --keyword '<app-code>' --by code --page-size 20` |
| Engineering standards | `bytedcli --json devspec guideline list --language Go --summary` |
| Named standard | `bytedcli --json devspec guideline get --name '<guideline-name>' --original` |
| Meego work items | `bytedcli --json meego workitem list --project-key '<project-key>' --mql '<MQL selecting named fields>'` |
| Known Meego item | `bytedcli --json meego workitem get --url '<meego-url>' --fields '["_all"]' --page-size 100` |
| Oncall tickets and messages | `bytedcli --json lark-oncall ticket list --title '<keyword>' --range 7d --page-size 20 --with-messages --message-limit 50` |
| Oncall documents | `bytedcli oncall document search --tenant-id '<tenant-id>' --keyword '<keyword>' --limit 5` |
| Personal Oncall flows | `bytedcli oncall flow search --keyword '<keyword>' --mine --last-days 90 --limit 10` |
| TCC namespaces | `bytedcli --json tcc namespace search '<keyword>' --scope all --page-size 50` |
| Settings businesses | `bytedcli --site cn --json settings biz search --keyword '<keyword>' --type sdk` |
| Data assets | `bytedcli --json coral search --region sg --query '<keyword>' --limit 20` |
| Hive table metadata | `bytedcli --json coral hive table get --region sg --db-name '<database>' --table-name '<table>'` |
| Hive lineage | `bytedcli --json coral hive table lineage --region sg --db-name '<database>' --table-name '<table>' --direction BOTH` |
| Permission knowledge | `bytedcli --json kani knowledge search --query '<question>' --result-limit 5` |
| Permission-check contract | `bytedcli kani openapi authz check --help` and `bytedcli kani openapi authz path --help` |
| Internal skill discovery | `bytedcli --json agentbuddy skill list --query '<keyword>' --scope internal --page-size 20` |
| Known internal skill | `bytedcli --json agentbuddy skill get --namespace '<namespace>' --name '<skill>'` |
| Log tools | `bytedcli --json argos tool list --namespace log` |

Use ByteTree for service ownership; AppInfo describes applications. Oncall
document search requires a tenant; flow search requires a tenant or `--mine`.
Meego MQL requires explicit selected fields and rejects `SELECT *`. Follow the
returned `next_page_token` with `--page-token` when an all-fields read is paginated.
Settings business search is CN-only in the audited implementation.

DevSpec defaults to cached reads. `--original` reads the source without updating
the cache; `--update` writes the cache. Select the actual Coral region from its
help; do not treat the example's `sg` as the user's target.

AFS provides service, interface, code, document, and static call-graph retrieval:

```sh
bytedcli --json ai-dev-pro afs psm search --q '<service description>' --limit 3
bytedcli --json ai-dev-pro afs interface search \
  --method-desc '<functionality>' --psm '<psm>' --limit 3
bytedcli --json ai-dev-pro afs code search --q '<code description>' --psm '<psm>' --limit 3
bytedcli --json ai-dev-pro afs doc abstract search --q '<document topic>' --limit 5
bytedcli --json ai-dev-pro afs callgraph method get \
  --psm '<psm>' --method-name '<method>' --up-depth 2 --down-depth 2
```

Call-graph results describe static code relationships, not live service traffic.
Adding `--business-line-path` to AFS PSM search invokes an internal agent in the
audited implementation; use it deliberately rather than assuming it is plain
retrieval. Prefer direct Argos tools for observability evidence. `argos run` is
an agent interface with configurable timeouts; omitting a PSM does not prove that
it always times out.

## One Context

Official entry points:

- [User guide](https://bytedance.larkoffice.com/docx/RtqndfsyeoYxIPxDm5KctROtnjA)
- [CLI and skill distribution](https://one-context-cli.gf.bytedance.net/)

Assume One Context is configured and authorized. Use its installed skill's current
source-routing and content-reading instructions, without a preliminary setup or
auth-status step. Resolve `<one-context-skill-root>` from that installed skill;
use its wrapper rather than calling the executable directly:

```sh
bash '<one-context-skill-root>/scripts/run-cli.sh' search --cli_protocol 4.6 \
  --queries '[{"query":"<self-contained question>"}]' \
  --traffic_app '<actual-agent-type>' --ignore_l4_data=false
bash '<one-context-skill-root>/scripts/run-cli.sh' knowledge list --cli_protocol 4.6 \
  --domain personal:group_chats --depth 1 \
  --traffic_app '<actual-agent-type>' --ignore_l4_data=false
```

Give each query one information goal and resolve pronouns. Read returned content
bundles and retain their source URLs. Distinguish indexed/generated context from
source-native data. Ingested memories are not the complete local transcript store.
The default Search source set does not imply every corporate knowledge index is
included; follow the installed skill's explicit source selection when needed.
Use the runtime's actual agent type for the traffic marker; follow the installed
skill's L4-selection rule if the user specifies one.

The 2026-10-28 server contract exposed `retrieve_context` and `list_data_domains`
at `https://lvkbr1fi.mcp.bytedance.net/mcp`. Mira's live `ByteDanceContext` package
pointed to that URL. The domain-list tool covers connected Hive/NL2Data and Prism
domains, not every dataset or permission.

Use the configured CLI instead of custom cookie/MCP plumbing. If a real request
reports an access error, distinguish missing scope, expired credentials, resource
permission, and index coverage. Follow the current error guidance and continue
independent source research. Do not turn historical authentication failures into
a default setup requirement, or assume tokens from different applications are
interchangeable. Research does not require changing conversation-upload hooks or
historical-import settings.

## Specialist interfaces

| Agent | Potential addition | Verify before assuming parity |
| --- | --- | --- |
| Mira | One Context, managed integrations, personal/project context | Attach retrieval directly where supported; existing Mira state is not automatically inherited |
| AIME | Imported space corpora and integrated OnCall/DevMind/etc. | Dataset metadata commands do not prove semantic chunk retrieval access |
| BitsAI | Engineering knowledge retrieval and BitsData relations | The documented MCP `ask` tool still invokes BitsAI Q&A |
| Tika | Claimed curated knowledge and semantic code search | The inspected wrapper exposes chat/history, not standalone knowledge retrieval |

Inspect installed chat/session help before consulting. Request focused answers
with sources; recover the existing session after timeouts. A successful chat
wrapper can print only an opening update: AIME's structured replay exposed the
final answer when the initial command did not.

For wrapper behavior, inspect `src/api/<agent>/`, `src/cli/handlers/<agent>/`, and
`src/cli/commands/<agent>/` in bytedcli. For Mira, inspect local `cis-mira/src/api/`
and `open_mira/mira_server`, `mira_harness`, and `mira_mcp_proxy`. The wrapper can
discard references or tool events; inspect structured history when actual
execution evidence is needed. Never treat a model's capability claim as a
verified backend contract.
