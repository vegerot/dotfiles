---
name: chrome-control
description: Control the user's real, signed-in Chrome Dev browser (their tabs, cookies, logins) from Antigravity via chrome-devtools-mcp / the chrome-devtools CLI with --autoConnect. Use whenever a task needs the user's actual browser session, or when Chrome DevTools tools fail to connect, show a blank/signed-out browser, or keep prompting "Allow remote debugging?".
---

# 🌐 Chrome Control: drive the user's real Chrome

Antigravity, Cursor, Grok, etc. have no built-in equivalent of the Claude or Codex Chrome extensions.
Agents that aren't Claude or Codex should use [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) instead.

> [!IMPORTANT]
> By default, chrome-devtools-mcp and the `chrome-devtools` CLI **launch a new, separate, signed-out Chrome profile**.
> That is rarely what we want. Always attach to the running browser with `--autoConnect --channel=dev`.
> If you see `about:blank` as the only page, you are in the wrong browser. Never sign in there.

## ✅ Setup (one time per machine)

1. Chrome 144+ (we use Chrome Dev). Open `chrome://inspect/#remote-debugging` and turn on remote debugging.
   Chrome then writes `DevToolsActivePort` (port + `/devtools/browser/<id>`) into its user-data directory.
2. Each new connection makes Chrome show **"Allow remote debugging?"**. The user clicks Allow. Keep one long-lived connection so this happens once.

## 💻 Use the CLI (`chrome-devtools`) by default

The CLI chains well: loops, pipes, and several actions in one shell command.
It talks to a background daemon. Two traps, both observed:

- If no daemon is running, any command **auto-starts an isolated, headless, blank browser**.
- In Antigravity, a daemon started by `chrome-devtools start` **dies when that command finishes**.

So, once per session, start the daemon in a background task that stays alive (`IsDaemon=true`):

```powershell
chrome-devtools start --autoConnect --channel=dev --categoryExtensions --experimentalVision --experimentalIncludeAllPages; while ($true) { Start-Sleep 30 }
```

```bash
chrome-devtools start --autoConnect --channel=dev --categoryExtensions --experimentalVision --experimentalIncludeAllPages && sleep infinity
```

Then run commands normally and chain them:

```powershell
chrome-devtools list_pages
chrome-devtools take_snapshot 3
chrome-devtools click 3 "2_5"; chrome-devtools evaluate_script "() => document.title" --pageId 3
```

- Required arguments are positional; check `chrome-devtools <command> --help` when unsure (`take_screenshot 3 --filePath x.png`, not `--pageId 3`).
- Prefer `take_snapshot` (text tree with element `uid`s) and `evaluate_script` over screenshots.
- Stop with `chrome-devtools stop` and kill the background task.
- MCP-only tools: `wait_for`, `fill_form`. Use the MCP for those.

## ⚡ The MCP tools (fallback)

Configured in `~/.gemini/config/mcp_config.json` (symlinked from dotfiles) with `bunx chrome-devtools-mcp@latest --auto-connect --channel=dev`.
Use `bunx` (not `npx` without `-y`, which hangs on `Ok to proceed?`). Restart agy after editing it.
The MCP server is already long-lived, so it needs no daemon setup.

```
call_mcp_tool(ServerName="chrome-devtools", ToolName="evaluate_script",
              Arguments={"pageId": 3, "function": "() => document.title"})
```

- Always pass `pageId`: `--pageIdRouting` is on by default, so page tools fail with `specify either a pageId or a serviceWorkerId` without it.
- `filePath` outputs must be inside a workspace root (`Access denied ... not within any of the configured workspace roots`). The CLI has no such limit.

The MCP server and the CLI daemon can both be attached to the same Chrome at once (tested 2026-10-19 on Windows).

## 📝 Page & extension tips

- For canvas editors (Google Docs), use APIs (`gws docs`) for content. Use the browser only for UI-only actions, with `press_key`/`type_text` instead of `fill`. `click_at` (from `--experimentalVision`) clicks by screenshot coordinates.
- Record video with `screencast_start` / `screencast_stop` (built in; no ffmpeg needed).
- `--categoryExtensions` exposes all extensions' service workers (`sw-*`) and `chrome-extension://` pages in `list_pages`, allows `evaluate_script --serviceWorkerId`, and includes content-script console logs. Note: `list_extensions` (`Extensions.getExtensions` in CDP) only lists **unpacked** developer extensions, not Chrome Web Store extensions.

## 🩺 When it does not connect

First check that the port file exists for the Chrome Dev profile:

| OS | `DevToolsActivePort` location |
|---|---|
| Windows | `%LOCALAPPDATA%\Google\Chrome Dev\User Data\` |
| macOS | `~/Library/Application Support/Google/Chrome Dev/` |
| Linux | `~/.config/google-chrome-unstable/` |

Do **not** probe `http://127.0.0.1:9222/json/version`: the server Chrome starts from `chrome://inspect` returns 404 for `/json/*`. Only the WebSocket path works.

| Symptom | Cause | Fix |
|---|---|---|
| No port file / `Could not connect to Chrome` | Remote debugging is off or Chrome is closed | Turn it on at `chrome://inspect/#remote-debugging` |
| Only `about:blank`, signed out | Launched a new profile instead of attaching | Add `--autoConnect --channel=dev`; for the CLI, see the daemon traps above |
| Many "Allow remote debugging?" prompts | A new connection per action (one-off scripts, CLI without a daemon) | Use the MCP, or one long-lived CLI daemon |
| Linux Flatpak Chrome Dev: port file not found | Profile lives in `~/.var/app/com.google.ChromeDev/config/google-chrome-unstable` | `ln -s ~/.var/app/com.google.ChromeDev/config/google-chrome-unstable ~/.config/google-chrome-unstable` |
| macOS `/browser` subagent: `Could not find DevToolsActivePort for chrome at .../Google/Chrome/` | `/browser` looks in the Chrome Stable profile | `ln -sf ".../Google/Chrome Dev/DevToolsActivePort" ".../Google/Chrome/DevToolsActivePort"` |
| CLI hits an unrelated process / stale daemon | Stale daemon pid or socket file | `chrome-devtools stop`, then start again |
| Devbox (headless Linux) | There is no real Chrome there | Out of scope; any Chrome there is a separate headless profile |

When stuck, read the source: `~/code/github.com/google/` (`src/BrowserManager.ts` `#connect`, `docs/cli.md`, etc.).
