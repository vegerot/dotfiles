# Trae model load plugin

This CLIProxyAPI plugin adds **Trae model load** to the web management menu.
It uses the standard ManagementAPI resource interface; CLIProxyAPI and Management
Center require no source patches. The resource page and data endpoint have no
extra login. Only model load, observation time, queue size when available, and
shared weekly quota are returned. Trae credentials stay in the Bun loopback.

The Go shared library is a small HTTP bridge. It serves the page from the existing
Trae loopback `/v1/load-page` and load JSON from `/v1/status?refresh=true`.
The TypeScript implementation and HTML live in `.config/opencode/plugins/trae/`.

Build on this Mac:

```sh
./.config/cliproxy/trae-load-plugin/build.sh
```

The script installs `trae-load.dylib` in `~/.cli-proxy-api/plugins`.
Configure CLIProxyAPI:

```yaml
plugins:
  enabled: true
  dir: /Users/bytedance/.cli-proxy-api/plugins
  configs:
    trae-load:
      enabled: true
```

Open the web management UI and select **Trae model load**. The plugin page is also
available at `/v0/resource/plugins/trae-load/load`; resource URLs are declared by
the plugin host and retain that prefix on CLIProxyAPI v8.

The page refreshes every 30 seconds while visible. The loopback coalesces refreshes
and runs `traex debug models --remote` at most once per 30 seconds for status reads.
It shows one entry per model, preferring Max. Standard and Max have one shared
reported load metric. Values may exceed 100%; the meter is capped visually but
the exact value remains visible. An absent queue size remains absent. Weekly
openrouter quota is secondary and collapsed. Failed refreshes retain the last
observation and display an error.

To disable, set `plugins.configs.trae-load.enabled: false`. The library has no
request execution, auth, scheduler, or quota-provider capabilities.
