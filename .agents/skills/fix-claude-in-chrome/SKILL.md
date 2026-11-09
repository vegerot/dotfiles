---
name: fix-claude-in-chrome
description: 'Diagnose and repair the Claude in Chrome / browser-control integration when `/chrome` cannot see the browser. Use this whenever the user says /chrome is broken, browser tools vanished, "Extension: Not detected", the claude-in-chrome MCP is missing or has 0 tools, browser automation stopped after a Claude Code update, or Claude cannot drive Chrome even though the extension is clearly installed. Also use it proactively before attempting any browser-automation task that fails to find a browser, and whenever the user runs a non-stable Chrome channel (Dev/Beta/Canary) or a non-Chrome Chromium browser.'
---

# Repairing Claude in Chrome

The browser integration fails in a handful of specific ways, and the UI is actively
misleading about which one you have. Diagnose before touching anything — most "fixes"
people try (reinstalling the extension, clicking *Reconnect*) cannot possibly work.

## Start here

Run the diagnostic from this skill's base directory (the path given when the skill loads):

```bash
bash <skill-base-dir>/scripts/diagnose.sh
```

Read-only. It prints every link in the chain, then a verdict naming the fault and the
exact repair. Exit 0 means healthy. Work from its verdict rather than guessing, and
re-run it after each repair.

## How the pipe actually works

Understanding the direction of travel saves you from a whole class of wrong theories:

```
extension → connectNative() → Chrome spawns ~/.claude/chrome/chrome-native-host
          → that execs `claude --chrome-native-host`
          → which listens on /tmp/claude-mcp-browser-bridge-$USER/<pid>.sock
          → Claude Code connects to that socket
```

**Chrome starts the chain.** Nothing on the Claude Code side can initiate it. That is why
*Reconnect extension* can never bootstrap a missing manifest, and why no amount of
restarting Claude Code helps.

Two facts that mislead almost everyone:

- **The sidebar chat working proves nothing.** It talks to claude.ai over ordinary HTTPS
  and never touches native messaging. Browser *control* is the opposite direction.
- **There is a second transport.** Browsers also reach Claude Code through a cloud relay
  (`wss://bridge.claudeusercontent.com`), which is how a browser on another machine can
  appear in your list. So the browser list can look healthy while the local pipe is dead,
  and a local socket can be absent even though tools work.

## The faults, and what actually fixes them

The script names one of these. Fix only what it names.

### `version-drift` — the common recurrence

The generated wrapper pins an **absolute version path**, so every Claude Code update
strands it:

```sh
# ~/.claude/chrome/chrome-native-host
exec "/Users/bytedance/.local/share/claude/versions/2.1.228" --chrome-native-host
#                                              ^^^^^^^ launcher has moved to 2.1.229
```

Repair, then harden so it stops recurring:

```bash
claude --chrome            # regenerates the wrapper at the current version
```

Then edit the last line to follow the launcher symlink instead of a version:

```sh
exec "/Users/bytedance/.local/bin/claude" --chrome-native-host
```

The file says *do not edit manually*, and that is fair — `claude --chrome` overwrites it
and re-pins a version, so re-apply this edit whenever you run that. The trade is worth it:
the symlink tracks updates, so the integration survives them. Do **not** point it at a
`claude` found on `PATH` — under cmux or similar wrappers that is a shim in a temp
directory whose path changes per panel.

After repairing, retire hosts still running the old binary so Chrome respawns them:

```bash
pkill -f 'chrome-native-host'
rm -f /tmp/claude-mcp-browser-bridge-$(id -un)/*.sock
```

### `manifest-wrong-browser` — non-stable channels

`claude --chrome` writes the manifest to a hardcoded list of browser **vendors**
(`chrome, brave, arc, edge, chromium, vivaldi, opera`) — but not to Chrome's release
**channels**. If the extension lives in Chrome Dev, Beta or Canary, it never sees a
manifest and can never connect.

Link the real manifest into the browser that holds the extension:

```bash
ln -sf ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json \
       ~/Library/Application\ Support/Google/Chrome\ Dev/NativeMessagingHosts/
```

A symlink rather than a copy, so it keeps tracking whatever `claude --chrome` regenerates.
Then quit and reopen the browser — manifests are read at startup.

### `no-manifest` — nothing written anywhere

Run `claude --chrome`. The `/chrome` menu will not do this for you: **"Install Chrome
extension" only opens the Web Store link.** If the extension is already installed, that
menu item is a dead end, which is why repeated `/chrome` runs feel like no-ops.

### `stale-hosts` / `orphan-sockets`

Hosts from a previous version still hold the sockets. Kill them as shown above. Chrome
respawns one on demand — usually not instantly, so do not wait in a polling loop.

### `no-extension`

Install from <https://claude.ai/chrome> **in the browser you actually use**. On macOS,
Chrome channels are entirely separate applications with separate profile trees.

### Headless Chrome (devbox): signed out after every restart

`diagnose.sh` does not detect this. Symptoms: after Chrome restarts, the browser drops out
of `list_connected_browsers`, and the extension's `options.html` shows "Log in".

Why: the extension keeps its tokens in `chrome.storage.session`, which every browser
restart clears. Desktop browsers recover through a silent claude.ai sign-in
(`launchWebAuthFlow`, `prompt=none`) that needs the claude.ai login cookie. A headless
browser has no such cookie, because claude.ai's Cloudflare check rejects `HeadlessChrome`,
even when a human clicks it through `chrome://inspect`. The extension does keep a refresh
token on disk (`diskRefreshToken`), so restore from that:

```bash
node <skill-base-dir>/scripts/restore-headless-auth.ts    # Node >= 22.18; CDP port 9222 by default
```

It runs the extension's own refresh inside its service worker over the Chrome DevTools
Protocol (CDP), saves the rotated refresh token, and does nothing if the extension is
already signed in. Chrome must have `--remote-debugging-port`. Max's devbox setup (tested
2026-11-09):

- Launch: `google-chrome-unstable --headless=new --disable-gpu --password-store=basic --no-first-run --user-data-dir=$HOME/.config/google-chrome-unstable --remote-debugging-port=9222`.
  Headless ignores the default profile unless `--user-data-dir` is passed. The profile's
  cookies need `--password-store=basic`. `--disable-gpu` because earlyoom kills the GPU
  process under memory pressure and Chrome then exits.
- The native host manifest must be in `<user-data-dir>/NativeMessagingHosts/` (symlink it).
- Installing the extension without a UI: put `{"external_update_url": "https://clients2.google.com/service/update2/crx"}`
  in `/opt/google/chrome-unstable/extensions/fcoeoabgfenejglbffodgkkbkcdhcgfn.json`, start
  Chrome once without Puppeteer (its `--disable-background-networking` blocks the
  download), then restart once to finish the delayed install.
- chrome-devtools-mcp refuses `chrome://` and extension pages, so use raw CDP for those.

If the script reports `no diskRefreshToken` or `invalid_grant`, sign in again. The
extension's OAuth flow uses PKCE (a per-sign-in secret, `codeVerifier`, stays in the
extension), so the approval can happen in another browser. Read the authorize URL from the
tab the extension opens. Max opens it in an Incognito window on his Mac and approves, then
copies the `chrome-extension://…/oauth_callback.html?code=…&state=…` address from the
failed page. In the extension's service worker, POST that code with the stored
`codeVerifier` to `https://platform.claude.com/v1/oauth/token`, and store the result the way
`restore()` in the script does. Pasting the code is safe: it is useless without the
verifier. The extension ignores a callback in a tab it did not open, so this exchange has
to be done by hand.

### A session uses another machine's browser instead of the local one

With several browsers connected, a session uses, in order: (1) the **persisted pick**,
`chromeExtension.pairedDeviceId` in `~/.claude.json` ("is the one picked last"); (2) a
browser **on this computer** (`onThisComputer: true`), but only when a host sends
`localDeviceIds`, and a plain CLI session has none even with the local native host
running; (3) otherwise it asks. Removing `pairedDeviceId` therefore makes a plain session
ask instead of picking the local browser (tested 2026-11-09). Read from the 2.1.321 binary. Hosts such as Remote Control pass the
pick on as `set_chrome_browser_hints` (`preferredDeviceId`, `localDeviceIds`). So a stale
pick of a remote browser beats the local one. `isLocal: true` only means the OS matches.
Fix: `select_browser` with the local `deviceId`. That rewrites `pairedDeviceId`, so new
sessions default to it, which you can check with the headless check below. Picking another
browser later moves the default again.

## Verify functionally, never by reading the panel

The `/chrome` panel is not trustworthy (see below). Confirm with a real tool call in a
throwaway headless session:

```bash
cd ~ && claude --chrome -p \
  'Call mcp__claude-in-chrome__list_connected_browsers and print the raw result.' \
  --allowedTools 'mcp__claude-in-chrome__list_connected_browsers'
```

A JSON array of browsers means the integration works. `isLocal: true` marks a browser on
this machine. `--allowedTools` matters: without it the headless run stalls on a permission
prompt that has no one to answer it.

Going further than that — creating or navigating tabs — hits a per-session permission
grant that the user must click inside the extension. That gate is normal behaviour, not a
fault, so do not treat it as evidence the repair failed.

## Signals that lie

| Signal | Reality |
|---|---|
| `Extension: Not detected` | Detection scans the same 7 hardcoded vendors, so it is a **permanent false negative** on Chrome Dev/Beta/Canary. It never turns green there, even when everything works. |
| `Browser: Browser 1` | This is the signal that matters. It appears, with a `Select browser…` item, only when a browser is genuinely connected. |
| Greyed *Manage permissions* / *Reconnect extension* | Gated on that same false flag. Both stay unavailable and neither is needed — permissions live in the extension's own settings. |
| The startup banner "Claude in Chrome extension detected" | A **different** code path from the `/chrome` panel. The two disagree; the banner is the more accurate of the two. |
| `Status: Disabled` | Real, and worth fixing: run `claude --chrome`, or flip `Enabled by default` in `/chrome` so ordinary sessions get browser tools. |

## Environment traps that cost real time

- **BSD tools reject GNU long flags.** On macOS `pgrep --full` and `pkill --full` match
  nothing while looking like they worked. Use `-f`, and put flags before the pattern:
  `pgrep -fl 'pattern'`. A `pgrep --full` inside an `until` loop will spin forever.
- **Do not `grep` for `chrome-native-host` alone** when hunting processes — it matches your
  own shell command line and invents a stale-host fault. Require the executable itself to
  be a claude binary.
- **Driving a nested Claude Code in tmux**: piping its output through `tee` breaks the TTY
  and kills the tmux server. Capture with `tmux capture-pane` instead. Blind
  `tmux send-keys Enter` on a dialog may also be refused by the permission classifier —
  prefer the headless `-p` check above, which has no dialogs.

## When none of the above fits

The client is a single large bundled binary, and reading it is a legitimate last resort
when the UI and the docs disagree:

```bash
BIN=$(readlink ~/.local/bin/claude)
rg -a -o 'com\.anthropic\.[a-zA-Z0-9_.]*' "$BIN" | sort -u        # host names
rg -a -o 'Chrome (Dev|Beta|Canary)' "$BIN" | sort -u              # channels it knows
rg -a -o 'chrome-extension://[a-p]{32}' "$BIN" | sort -u          # expected extension id
```

`rg -a` is required — the binary is ~290 MB and is otherwise skipped as binary.

If you confirm a genuine upstream gap, file it with `/feedback`. Run it from a **non-git
scratch directory**: `/feedback` attaches git metadata from the launch directory, there is
no toggle for it, and that would send the repo URL, branch and dirty state to an external
service for a bug that has nothing to do with the repo. Choose "this session only" for the
transcript, and prefer a freshly spawned session so nothing from the real conversation
travels with it.
