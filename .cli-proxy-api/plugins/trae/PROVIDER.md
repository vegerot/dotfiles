# TraeX Provider Plugin for CLIProxyAPI

This Go C-ABI plugin (`trae.dylib`) exposes your local **TraeX (`traex`)** model catalog and subscription inside [`cliproxyapi`](https://github.com/router-for-me/CLIProxyAPI) without copying static tokens into configuration files.

## Files

- `provider.go` — Core catalog discovery (`models_cache.json`), token reading/refresh (`auth.json` + `traex models`), OpenAI-to-Trae raw chat request translation, and Trae SSE-to-OpenAI response/stream translation.
- `rpc.go` — CLIProxyAPI v1 plugin JSON-RPC method dispatch (`auth.*`, `model.*`, `executor.*`, `response.normalize_before`).
- `cmd/trae/main.go` — C-ABI shared library entrypoint (`cliproxy_plugin_init` with `RTLD_NODELETE` constructor pin and `host.stream.emit`/`host.stream.close` callbacks).
- `provider_test.go` — Black-box unit tests (`package trae_test`).
- `Makefile` — Builds `~/.cli-proxy-api/plugins/darwin/arm64/trae.dylib`.

## Configuration

1. **`/opt/homebrew/etc/cliproxyapi.conf`**:
   ```yaml
   plugins:
     enabled: true
     dir: "~/.cli-proxy-api/plugins"
     configs:
       trae:
         enabled: true
   ```
2. **`~/.cli-proxy-api/trae.json`**:
   ```json
   {
     "type": "trae",
     "disabled": false
   }
   ```
   *(No secret is stored in `~/.cli-proxy-api/trae.json`; the plugin reads `.trae.access_token` directly from `$TRAECLI_HOME/auth.json` or `~/.trae/cli/auth.json` on each request and runs `traex models` automatically on `401`/`403`.)*
