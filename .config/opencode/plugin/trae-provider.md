# Trae provider

`trae-provider.ts` adapts OpenCode's OpenAI Chat requests to Trae's raw-chat API and translates Trae's named server-sent events back to OpenAI Chat events. It uses OpenCode V2's provider-scoped request, response, and retry hooks; there is no loopback server.

## Ownership

- Trae owns authentication in `$TRAECLI_HOME/auth.json` and refreshes it through `traex models`.
- Trae owns model discovery in `$TRAECLI_HOME/models_cache.json` and refreshes it through `traex debug models --remote`.
- The plugin owns only protocol translation and OpenCode model registration.

The catalog is loaded from cache before one process-wide background refresh. This is intentional: local parsing was measured in milliseconds, while a remote refresh took about four seconds. Standard and Max routes are separate OpenCode models because their backend keys and context limits differ.

## Verified protocol assumptions

Captured Trae traffic and live requests established that:

- authentication uses `Cloud-CLI-JWT`;
- `config_name` and `model_name` are distinct route identifiers;
- tool parameter schemas must be JSON strings;
- historical tool calls use `function_call` rather than `function`;
- `progress_notice` contains non-JSON data and must remain SSE control traffic;
- `x-app-id`, `x-ide-function`, and `x-ide-version-code` are required—a 2026-09-25 omission probe produced Trae `error` events without each one;
- `originator`, `version`, and `x-agent-flag` are not required—the same probe completed normally without all three.

Malformed JSON model events fail loudly so protocol drift does not silently truncate a response. Images are not advertised because image translation has not been verified.

## Verification

Run deterministic translation tests:

```sh
bun test './.config/opencode/plugin/trae-provider.test.ts'
```

Run live text, tool, and long-context checks:

```sh
./.config/opencode/plugin/trae-provider-smoke.sh
```

Set `OPENCODE_TRAE_DEBUG=1` before starting OpenCode to include successful request and stream lifecycle records in `~/.local/share/opencode/log/trae-provider.log`. Catalog changes, authentication refreshes, and errors are always logged.
