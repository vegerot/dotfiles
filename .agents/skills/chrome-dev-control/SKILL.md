---
name: chrome-dev-control
description: Control, inspect, and automate the user's live, signed-in Google Chrome Dev browser in Antigravity. Use whenever the user asks to inspect open tabs, interact with or read a web page in Chrome, drive browser workflows (Google Docs/Sheets, ChatGPT, Lark, etc.), or automate tasks requiring user logins, cookies, or extensions.
---

# 🌐 Chrome Dev Control (Live Browser Automation)

This skill guides controlling the user's live, signed-in **Google Chrome Dev** browser (`/Applications/Google Chrome Dev.app`) on macOS in Antigravity.

---

## 🧭 Architecture & Core Rules

1. **Target**: Connects to the user's actual Chrome Dev instance listening with remote debugging on `127.0.0.1:9222`.
2. **Never Launch Isolated Headless Chrome**: If flags or daemon connection are omitted, tools may start an empty, headless, signed-out browser. **Always ensure `--channel=dev` or `--auto-connect` is used.**
3. **One Persistent Connection**: Every new CDP connection causes Chrome Dev to display an "Allow remote debugging?" prompt. Running a long-lived daemon (`chrome-devtools start --autoConnect --channel=dev`) or using the native Antigravity MCP server keeps the connection open and eliminates repeated prompts.
4. **Snapshot Over Screenshot**: Always prefer `take_snapshot` (accessibility tree with element `uid`s) over `take_screenshot`. Snapshots are fast, token-efficient, unambiguous, and directly actionable.
5. **Fresh Snapshots**: Element `uid`s are valid only for the snapshot in which they were generated. After any click, navigation, or DOM change, take a fresh snapshot before interacting with new elements.

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

The CLI binary is installed globally at `/opt/homebrew/bin/chrome-devtools`.

### Daemon Management
- **Check Status**: `chrome-devtools status`
- **Start Daemon**: `chrome-devtools start --autoConnect --channel=dev`
- **Stop Daemon**: `chrome-devtools stop`

### ⚠️ Critical CLI Syntax Rule
In the `chrome-devtools` CLI, **required arguments must be positional** (not flags), while optional options use `--flags`:
- **Correct**: `chrome-devtools click 1 "2_5"`
- **Incorrect**: `chrome-devtools click --pageId 1 --uid "2_5"`
- **Correct**: `chrome-devtools new_page "https://example.com"`
- **Correct**: `chrome-devtools navigate_page 1 --url="https://example.com"`

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
| Repeated "Allow remote debugging?" prompts | New connections started per command. | Keep the daemon running: `chrome-devtools start --autoConnect --channel=dev`. |
| Element not found or invalid `uid` | DOM changed since previous snapshot. | Call `take_snapshot` again and use the new `uid`. |
| Connection refused on `127.0.0.1:9222` | Chrome Dev is not running or remote debugging is disabled. | Start Chrome Dev with remote debugging enabled (`chrome://inspect/#remote-debugging` or `--remote-debugging-port=9222`). |
| `Error: Unknown argument` in CLI | Required parameters passed as flags instead of positionals. | Pass required parameters positionally (e.g. `chrome-devtools click 1 "1_2"`). |
