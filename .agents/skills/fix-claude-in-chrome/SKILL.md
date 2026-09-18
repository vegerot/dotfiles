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
