---
name: chrome-dev-control
description: Control, inspect, and automate the user's live, signed-in Google Chrome Dev browser in Antigravity. Use whenever the user asks to inspect open tabs, interact with or read a web page in Chrome, drive browser workflows (Google Docs/Sheets, ChatGPT, Lark, etc.), or automate tasks requiring user logins, cookies, or extensions.
---

# 🌐 Chrome Dev Control (Live Browser Automation)

This skill guides controlling the user's live, signed-in **Google Chrome Dev** browser across platforms (Linux, macOS, and Windows) in Antigravity.

---

## 🧭 Architecture & Core Rules

1. **Target**: Connects to the user's actual live Chrome Dev instance listening with remote debugging on `127.0.0.1:9222` (or via `DevToolsActivePort`).
   - Enable by visiting `chrome://inspect/#remote-debugging` in Chrome Dev and checking "Enable remote debugging".
   - Fast tab launch shortcut:
     - **Linux**: `google-chrome-unstable "chrome://inspect/#remote-debugging"`
     - **macOS**: `open -a "Google Chrome Dev" "chrome://inspect/#remote-debugging"`
     - **Windows**: `Start-Process "chrome.exe" "chrome://inspect/#remote-debugging"`
2. **Platform Matrix**:

| Platform | Chrome Executable | Profile / User Data Dir | CDP Discovery / Port | Global CLI Binary |
|---|---|---|---|---|
| **Linux** | Flatpak `com.google.ChromeDev` / wrapper `~/.local/bin/google-chrome-unstable` | `~/.var/app/com.google.ChromeDev/config/google-chrome-unstable` (symlinked $\rightarrow$ `~/.config/google-chrome-unstable`) | `~/.config/google-chrome-unstable/DevToolsActivePort` | `~/.npm-global/bin/chrome-devtools` |
| **macOS** | `/Applications/Google Chrome Dev.app` | `~/Library/Application Support/Google/Chrome Dev` | `DevToolsActivePort` | `/opt/homebrew/bin/chrome-devtools` |
| **Windows** | `C:\Program Files\Google\Chrome Dev\Application\chrome.exe` | `%LOCALAPPDATA%\Google\Chrome Dev\User Data` | `DevToolsActivePort` | `%USERPROFILE%\.bun\bin\chrome-devtools.exe` |

3. **Never Launch Isolated Headless Chrome**: If flags or daemon connection are omitted, tools may start an empty, headless, signed-out browser (`about:blank`). **Always ensure `--channel=dev` or `--auto-connect` is used.**
4. **One Persistent Connection**: Every new CDP connection causes Chrome Dev to display an "Allow remote debugging?" prompt. Running a long-lived daemon (`chrome-devtools start --autoConnect --channel=dev`) or using the native Antigravity MCP server keeps the connection open and eliminates repeated prompts.
5. **Snapshot Over Screenshot**: Always prefer `take_snapshot` (accessibility tree with element `uid`s) over `take_screenshot`. Snapshots are fast, token-efficient, unambiguous, and directly actionable.
6. **Fresh Snapshots**: Element `uid`s are valid only for the snapshot in which they were generated. After any click, navigation, or DOM change, take a fresh snapshot before interacting with new elements.
7. **Source Code & Documentation**: The `chrome-devtools-mcp` repository is cloned locally at `~/code/github.com/google/`. Inspect it whenever you need exact tool schemas, CLI argument definitions (`scripts/generate-cli.ts`), or connection logic.

---

## 🛠️ Interface 1: Native Antigravity MCP Tools (Preferred)

The `chrome-devtools` server is configured in `~/.gemini/config/mcp_config.json`. When loaded, call its tools using `call_mcp_tool`:

```json
call_mcp_tool(
  ServerName="chrome-devtools",
  ToolName="list_pages",
  Arguments={}
)
```

### Essential MCP Tool Reference

| Tool | Key Arguments | Purpose |
|---|---|---|
| `list_pages` | `{}` | Lists all open tabs, page indices, URLs, titles, and active selection. |
| `select_page` | `{"pageId": 1}` | Selects the active target tab for subsequent context-sensitive calls. |
| `new_page` | `{"url": "https://..."}` | Opens a new tab and navigates to the URL. |
| `close_page` | `{"pageId": 3}` | Closes the specified tab. |
| `navigate_page` | `{"pageId": 1, "url": "https://...", "type": "url"}` | Navigates or reloads (`type`: `url`, `reload`, `back`, `forward`). |
| `take_snapshot` | `{"pageId": 1}` | Returns text-based accessibility tree with element `uid`s. |
| `take_screenshot` | `{"pageId": 1}` | Takes a visual screenshot (use only when visual layout/rendering must be inspected). |
| `click` | `{"pageId": 1, "uid": "2_5"}` | Clicks element by its snapshot `uid`. |
| `fill` | `{"pageId": 1, "uid": "2_7", "value": "text"}` | Types text into an input/textarea or selects an option. |
| `type_text` | `{"pageId": 1, "text": "hello"}` | Types text using keyboard into the currently focused element. |
| `press_key` | `{"pageId": 1, "key": "Enter"}` | Sends a key press (`Enter`, `Escape`, `Tab`, `Control+f`). |
| `evaluate_script` | `{"pageId": 1, "function": "() => document.title"}` | Evaluates JavaScript expression in page and returns serialized JSON. |
| `wait_for` | `{"pageId": 1, "text": "Welcome"}` | Waits for text or element to appear on page. |

---

## 💻 Interface 2: `chrome-devtools` CLI (Fallback & Scripting)

The CLI binary is installed globally via `npm install --global chrome-devtools-mcp`:
- **Linux**: `~/.npm-global/bin/chrome-devtools` (and `chrome-devtools-mcp`)
- **macOS**: `/opt/homebrew/bin/chrome-devtools`
- **Windows**: `%USERPROFILE%\.bun\bin\chrome-devtools.exe` or `%APPDATA%\npm\chrome-devtools.cmd`

### Daemon Management
- **Check Status**: `chrome-devtools status`
- **Start Daemon**: `chrome-devtools start --autoConnect --channel=dev`
- **Stop Daemon**: `chrome-devtools stop`

### ⚠️ Critical CLI Syntax Rules
In the `chrome-devtools` CLI, **required arguments must be positional** (not flags), while optional options use `--flags`:
- **Take snapshot**: `chrome-devtools take_snapshot 1`
- **Click element**: `chrome-devtools click 1 "2_5"`
- **Fill input**: `chrome-devtools fill 1 "2_7" "search text"`
- **Navigate tab**: `chrome-devtools navigate_page 1 --url="https://example.com"`
- **New tab**: `chrome-devtools new_page "https://example.com"`
- **Evaluate JS**: `chrome-devtools evaluate_script "() => document.title" --pageId 1`
- **Incorrect (will error)**: `chrome-devtools click --pageId 1 --uid "2_5"`

> [!NOTE]
> `wait_for` and `fill_form` are MCP-only tools and are not exposed as CLI subcommands. In shell scripts, use sleep loops or `evaluate_script` checks instead.

---

## 📋 Common Automation Workflows

### 1. Inspecting or Reusing an Existing Tab
1. Call `list_pages` to scan open tabs.
2. Find the tab matching the desired domain/title.
3. If not found, open a new tab with `new_page`.

### 2. Standard Click & Form Interaction Flow
1. Navigate or select tab (`navigate_page` or `select_page`).
2. Run `take_snapshot` to locate target inputs/buttons and their `uid`s.
3. Call `fill(uid=..., value=...)` for text inputs or `click(uid=...)` for buttons.
4. After submission/navigation, take a **new** `take_snapshot` to confirm the resulting state.

### 3. Google OAuth & Unverified App Consent
When driving Google OAuth consent for developer tools (`gws`, local clients):
1. **Choose Account**: Snapshot and click `link "<Name> <email>"`.
2. **"Google hasn’t verified this app" Warning**:
   - Snapshot and find `link "Advanced"`. Click it.
   - Take new snapshot and click `link "Go to <App Name> (unsafe)"`.
3. **Permissions Screen**:
   - Snapshot and find `checkbox "Select all"`. Click it.
   - Snapshot and verify all scopes are checked.
   - Click `button "Continue"`.
4. Close the tab once the callback redirect completes.

### 4. Rich Text & Contenteditable Editors
- For complex web editors (e.g. Google Docs canvas, Slate editors, Notion):
  - Standard `fill` may not dispatch necessary framework input events.
  - Click the editor element to focus it, then use `type_text` or `evaluate_script` to dispatch input/paste events.
  - For Google Docs: prefer Google Workspace APIs (`gws docs`) for document body manipulation; use browser automation for UI-only actions like embedding live Sheets charts (Insert → Chart → From Sheets).

---

## 🔍 Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `Could not find Google Chrome executable for channel 'stable'` | Default channel is stable, but Chrome Dev is installed. | Pass `--channel=dev` to the CLI or daemon. |
| `Could not find DevToolsActivePort for chrome-dev at ~/.config/google-chrome-unstable/DevToolsActivePort` | On Linux, Chrome Dev runs via Flatpak in `~/.var/app/com.google.ChromeDev/config/google-chrome-unstable/`, or remote debugging is not enabled. | 1. Ensure `~/.config/google-chrome-unstable` is symlinked to `~/.var/app/com.google.ChromeDev/config/google-chrome-unstable`.<br>2. In Chrome Dev, navigate to `chrome://inspect/#remote-debugging` and check "Enable remote debugging". |
| Repeated "Allow remote debugging?" prompts | New connections started per command. | Keep the daemon running: `chrome-devtools start --autoConnect --channel=dev`. |
| CLI starts an isolated, empty browser (`about:blank`) | Running CLI tool without active daemon or without `--channel=dev --autoConnect`. | Start daemon first: `chrome-devtools start --autoConnect --channel=dev`. |
| Element not found or invalid `uid` | DOM changed since previous snapshot. | Call `take_snapshot` again and use the new `uid`. |
| Connection refused on `127.0.0.1:9222` | Chrome Dev is not running or remote debugging is disabled. | Start Chrome Dev with remote debugging enabled (`chrome://inspect/#remote-debugging` or `--remote-debugging-port=9222`). |
| `Error: Unknown argument` in CLI | Required parameters passed as flags instead of positionals. | Pass required parameters positionally (e.g. `chrome-devtools click 1 "1_2"`). |
