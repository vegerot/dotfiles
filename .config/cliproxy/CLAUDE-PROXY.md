# Claude Code through CLIProxyAPI

Run `claude-proxy` and open `/model`. The command fetches the same live chat
catalog used by Pi and OpenCode, removes media/hidden models, prefers Trae Max,
and supplies a temporary `modelPicker` configuration to Claude Code. It does not
change normal `claude` settings or your Claude subscription login.

```sh
claude-proxy
claude-proxy --model grok-4.7
claude-proxy --model GPT-6.1-Sol-Max --effort high
```

The default proxy model is Trae GPT-6.1-Sol-Max. Claude's built-in Sonnet/Opus
aliases route to CLIProxyAPI's Claude Sonnet/Opus models; its background Haiku
alias routes to Seed-2.1-Turbo. The proxy uses the Anthropic Messages API at
`http://127.0.0.1:8317`, with a local client token. `CLIPROXY_URL` and
`CLIPROXY_API_KEY` override the endpoint/key. Launch requires Bun and a running
CLIProxyAPI service. Temporary settings are deleted after the child exits.

Claude Code 2.1.300 also supports `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1`.
We verified it discovers models, but CLIProxyAPI's Claude catalog includes media
and duplicate Standard/Max routes. The wrapper uses the shared filtered catalog
and disables this second discovery path.

## Context limits and model selection

Picker descriptions show upstream context limits; those labels do not change
Claude Code's capability handling. For unrecognized model IDs, Claude assumes a
200K context window. We keep that conservative default rather than pretending
Grok, GPT, DeepSeek, or Seed has a Claude model's capabilities via `behavesAs`.
For a launch fixed to a known window, Claude supports the documented
`CLAUDE_CODE_MAX_CONTEXT_TOKENS` override; do not leave a larger override active
when switching to a smaller model.

In `/model`, press **s** for a session-only change. Enter saves the model as the
normal Claude user default; prefer **s** so a proxy-only ID does not become the
default for ordinary `claude` sessions. The wrapper selects its proxy default at
launch regardless of your normal default.

## Verification

On Claude Code 2.1.300:

- The generated picker appears interactively with the filtered catalog.
- Live Trae GPT-6.1-Sol-Max text request returned PONG.
- Live Grok 4.7 executed `printf CLAUDE_PROXY_TOOL_OK` and returned PONG.
- The command passed a headless `--bare --print` text check. Bare mode uses an
  explicit API key; ordinary launches use ANTHROPIC_AUTH_TOKEN.

This config is for Claude Code in the terminal. It does not add models to ordinary
Claude web chats or the Claude desktop app.
