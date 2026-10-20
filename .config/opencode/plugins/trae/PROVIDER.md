# Trae and CLIProxyAPI providers

OpenCode and Pi share discovery in `.config/cliproxy/catalog.ts`. Each has a small adapter for its host API. OpenCode keeps Trae-owned models under `trae/` so the quota/load footer and `/trae-status` continue to work; other chat models appear under `cliproxy/`. Pi exposes the full catalog under `cliproxy`.

Both clients send ordinary OpenAI Chat requests to CLIProxyAPI at `127.0.0.1:8317/v1`. For Trae routes, CLIProxyAPI forwards to the Bun loopback server at `127.0.0.1:43821/v1`. `protocol.ts` owns Trae authentication and request/stream translation; `server.ts` owns HTTP serving, 401 refresh/retry, and syncing the Trae routes into CLIProxyAPI. OpenCode's adapter has no request, response, or retry hooks.

## Discovery and ownership

- Trae owns authentication in `$TRAECLI_HOME/auth.json` and its model cache in `$TRAECLI_HOME/models_cache.json`. The daemon refreshes the cache and watches for changes.
- Shared discovery combines CLIProxyAPI's rich Codex catalog (`/models?client_version=…`) with the ordinary `/models` ownership list. The optional Trae loopback catalog supplies missing output caps.
- Media and hidden/disabled routes are excluded. Standard and Max routes remain distinct. Supported reasoning efforts become OpenCode variants and Pi thinking levels.
- OpenCode discovers on startup, refreshes every 30 seconds, replaces removed routes, and persists the last successful catalog in plugin storage. Failed discovery retains that catalog.
- Pi owns its `models-store.json` cache and native refresh hook, including offline startup. Fixed-effort models may reason without advertising selectable effort levels.
- `CLIPROXY_URL`, `CLIPROXY_API_KEY`, and `TRAE_OPENAI_URL` override the local endpoints/key for both clients.

Install `.config/cliproxy/` alongside the Pi extension and OpenCode plugin. The dotfiles bootstrap installs these files; on this machine `~/.config/cliproxy` links to the tracked directory. The shared module sits outside either host's plugin discovery directory.

## Verified protocol assumptions

Captured Trae traffic and live requests established that:

- authentication uses `Cloud-CLI-JWT`;
- `config_name` and `model_name` are distinct route identifiers;
- tool parameter schemas must be JSON strings;
- historical tool calls use `function_call` rather than `function`;
- `cache_creation_input_tokens` maps to OpenCode cache-write usage;
- `progress_notice` contains non-JSON data and must remain SSE control traffic;
- `x-app-id`, `x-ide-function`, and `x-ide-version-code` are required—a 2026-09-25 omission probe produced Trae `error` events without each one;
- `originator`, `version`, and `x-agent-flag` are not required—the same probe completed normally without all three.

Malformed JSON model events fail loudly so protocol drift does not silently truncate a response. Image input is advertised from each cached model's `input_modalities`. OpenCode's OpenAI-compatible driver emits `image_url` content parts, which Trae raw chat accepts unchanged; a live standalone request correctly identified a generated solid-red PNG.

A 2026-09-28 probe found no usable raw-chat semantics for `verbosity`, `temperature`, `top_p`, `seed`, frequency/presence penalties, `stop`, `response_format`, or `tool_choice`. Unknown and malformed values were generally accepted but ignored; `stop` did not stop output, JSON mode returned plain text, low/high verbosity had overlapping output lengths, and `tool_choice` neither prevented nor forced tool calls. Named tool choice returned HTTP 400. The provider deliberately does not forward these controls without behavioral evidence.

## Verification

Run deterministic translation tests:

```sh
bun test './.config/opencode/plugins/trae' './.config/cliproxy'
```

Run live text, tool, and long-context checks:

```sh
./.config/opencode/plugins/trae/trae-provider-smoke.sh
```

Verify a reasoning variant or image input without restarting or interrupting the shared service:

```sh
opencode run --standalone \
  --model 'trae/GPT-5.6-Terra#high' \
  'Reply with exactly: TRAE_REASONING_VARIANT_OK'

opencode run --standalone \
  --model 'trae/GPT-5.6-Terra#low' \
  --file /path/to/image.png \
  'Describe the attached image.'
```

Discovery failures flow through OpenCode's service log. Trae protocol failures are returned by the loopback server; its process output belongs to the LaunchAgent. Neither adapter maintains a private append-only log.

## Historical direct-provider verification

After removing private logging and request-correlation state:

- all seven deterministic catalog, request, stream, and retry tests pass;
- the provider bundles to 13.1 KB and contains 453 lines / 15,339 bytes;
- all 25 Trae routes appear in `opencode models`;
- live text generation, shell-tool execution, and long-context `progress_notice` handling pass;
- the former private log does not grow after the restarted service handles those requests.

Capture `opencode models` before filtering it when checking model counts. A direct pipeline intermittently reported zero even though the command emitted all 25 Trae routes; redirecting stdout and then searching the file produced the correct result.

## Shared-catalog verification (2026-10-20)

- 24 deterministic tests pass, covering protocol translation, 401 retry, quota/status, media filtering, output caps, provider ownership, and removal of stale routes.
- Standalone OpenCode lists 12 `trae/` routes and 12 `cliproxy/` routes. Starting with CLIProxyAPI pointed at a closed port restores the same 24 routes from plugin storage.
- Live OpenCode requests through `trae/GPT-6.1-Sol#low` and `cliproxy/grok-4.7#low` each returned `PONG`. Pi's Trae request and offline catalog restoration also returned `PONG`.
- A local fake catalog changed a route from `Before` to `After`; the 30-second refresh persisted the new route and reloaded the provider once, then cleanup stopped the timer and aborted discovery.
- Bun bundles both the daemon and Pi adapter successfully. Interactive footer rendering was not manually exercised during this refactor; its existing tests pass and its implementation is unchanged.

An already-running OpenCode service needs its plugins reloaded or the service restarted to adopt source changes. Standalone verification uses a private server and does not interrupt existing sessions.
