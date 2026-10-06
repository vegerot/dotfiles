---
name: fix-antigravity-browser
description: Diagnose and repair Antigravity's live Chrome DevTools and `/browser` subagent connections across macOS, Debian Linux, headless servers (devbox), and Windows 11. Use whenever `/browser` fails with "Could not find DevToolsActivePort", connection refused on port 9222, Chrome is running but undetected, or browser automation drops.
---

# 🌐 Repairing Antigravity Live Chrome & `/browser` Connection

Antigravity interacts with Chrome via the **Chrome DevTools Protocol (CDP)** using `chrome-devtools-mcp` (both for the built-in `/browser` subagent and direct in-session MCP tools).

When `/browser` or browser tools fail, run the read-only diagnostic from this skill's directory:

```bash
bash <skill-base-dir>/scripts/diagnose.sh
# Or automatically apply the detected repair:
bash <skill-base-dir>/scripts/diagnose.sh --fix
```

---

## 🧭 Machine Profiles & Instant Repairs

| Machine | Environment | Chrome Type | Root Cause | 1-Step Repair |
|---|---|---|---|---|
| **macOS** *(Work Mac)* | GUI Desktop | `Google Chrome Dev.app` | Port written to `Google Chrome Dev/`, MCP looks in `Google/Chrome/` | Symlink `Google Chrome Dev` $\rightarrow$ `Google/Chrome` |
| **Debian Desktop** | GUI Desktop | Flatpak `com.google.ChromeDev` | Profile isolated in `~/.var/app/...` | Symlink Flatpak profile $\rightarrow$ `~/.config/google-chrome-unstable` |
| **ByteDance Devbox** | Headless Linux VM | Native deb package | Headless server ($DISPLAY unset), Chrome not running | Launch headless Chrome daemon with ephemeral debugging port |
| **Windows 11 PC** | GUI Desktop | `chrome.exe` (Dev) | Tool subprocess exit terminates ephemeral CDP sockets | Start persistent background daemon |

---

## 🛠️ Platform Repairs

### 1. macOS (Work MacBook)
Chrome Dev writes its port to `~/Library/Application Support/Google/Chrome Dev/DevToolsActivePort`, but standard `chrome-devtools-mcp` defaults to the stable directory.

```bash
mkdir -p "$HOME/Library/Application Support/Google/Chrome"
ln -sf "$HOME/Library/Application Support/Google/Chrome Dev/DevToolsActivePort" \
       "$HOME/Library/Application Support/Google/Chrome/DevToolsActivePort"
```

### 2. Debian Desktop (Linux GUI / Flatpak)
Flatpak isolates the user profile under `~/.var/app/com.google.ChromeDev/`:

```bash
mkdir -p "$HOME/.config"
ln -sf "$HOME/.var/app/com.google.ChromeDev/config/google-chrome-unstable" \
       "$HOME/.config/google-chrome-unstable"
```

### 3. Linux Headless Server / Devbox (Missing Display)
On headless servers over SSH, `$DISPLAY` is unset and Chrome is **never running by default**. Launch an ephemeral headless daemon:

```bash
nohup google-chrome \
  --headless=new \
  --remote-debugging-port=0 \
  --remote-allow-origins='*' \
  --user-data-dir="$HOME/.config/google-chrome" \
  --no-first-run > /dev/null 2>&1 &
```
* Chrome automatically allocates an open port, writes `~/.config/google-chrome/DevToolsActivePort`, and `/browser` connects immediately.

### 4. Windows 11
Processes spawned by agent tool steps terminate on exit, severing CDP connections. Maintain a persistent background daemon:

```powershell
chrome-devtools start --autoConnect --channel=dev
```

---

## 🔍 Verification

After applying the repair for your machine, verify connectivity by listing pages:
```bash
chrome-devtools list_pages
```
Or via native MCP `call_mcp_tool(ServerName="chrome-devtools", ToolName="list_pages")`.
Once tabs appear, `/browser` and in-session tools will succeed cleanly.
