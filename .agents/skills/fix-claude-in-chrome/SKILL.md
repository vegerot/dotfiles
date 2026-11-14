---
name: fix-claude-in-chrome
description: 'Diagnose and repair the Claude in Chrome / browser-control integration when `/chrome` cannot see the browser. Max uses Chrome Dev on every machine (Mac, devbox, Windows), never stable. Use this whenever the user says /chrome is broken, browser tools vanished, "Extension: Not detected", the claude-in-chrome MCP is missing or has 0 tools, browser automation stopped after a Claude Code update, or Claude cannot drive Chrome even though the extension is clearly installed. Also use it proactively before a browser-automation task that fails to find a browser, and when setting up Chrome Dev on a new machine.'
---

# Repairing Claude in Chrome (Chrome Dev)

Max runs **Chrome Dev** everywhere and never Chrome stable. The integration fails in a
handful of specific ways, and the UI misleads about which one you have. Diagnose before
touching anything: reinstalling the extension or clicking *Reconnect* cannot fix any of them.

## Start here

Run the diagnostic from this skill's base directory (the path given when the skill loads):

```bash
bun <skill-base-dir>/scripts/diagnose.ts
```

Read-only, for Mac and Linux. It prints every link in the chain, then a verdict naming each
fault and the exact repair commands. Exit 0 means healthy. Work from its verdict, and run it
again after each repair.

## How the pipe works

```
extension → connectNative() → Chrome reads <user data dir>/NativeMessagingHosts/<manifest>
          → spawns ~/.claude/chrome/chrome-native-host
          → that execs `claude --chrome-native-host`
          → which listens on /tmp/claude-mcp-browser-bridge-$USER/<pid>.sock
          → Claude Code connects to that socket
```

**Chrome starts the chain.** Nothing on the Claude Code side can start it. That is why
*Reconnect extension* can never fix a missing manifest, and why restarting Claude Code
does not help.

- **The sidebar chat working proves nothing.** It talks to claude.ai over ordinary HTTPS
  and never touches native messaging.
- **There is a second transport.** Browsers also reach Claude Code through a cloud relay
  (`wss://bridge.claudeusercontent.com`), which is how a browser on another machine appears
  in your list. So the list can look healthy while the local pipe is dead.

## Chrome Dev setup: link the stable folder (once per machine)

`claude --chrome` writes the manifest **only to Chrome stable's folder**. Its browser table
lists vendors (Chrome, Brave, Arc, Edge, Chromium, Vivaldi, Opera), not Chrome's release
channels. Chrome reads per-user manifests from `<user data dir>/NativeMessagingHosts`
(Chromium `chrome_paths.cc`, `DIR_USER_NATIVE_MESSAGING`). So make the stable folder a link
to Chrome Dev's. Then everything Claude Code writes for "Chrome" lands in Chrome Dev.

| Machine | Stable folder → Chrome Dev folder | State |
|---|---|---|
| Work Mac | `~/Library/Application Support/Google/Chrome` → `Chrome Dev` | done 2026-11-13; old data in `Google/Chrome.stable-backup` |
| devbox | `~/.config/google-chrome` → `google-chrome-unstable` | done 2026-11-13; old data in `~/.config/google-chrome.stable-backup` |
| Windows PC | nothing to link | `claude --chrome` writes `HKCU\Software\Google\Chrome\NativeMessagingHosts`, and Chromium reads that key for every channel (hardcoded in `launch_context_win.cc`). Checked 2026-11-13: Chrome Dev runs, the extension is in its `Default` profile, the manifest is registered there, and `HKCU\Software\Google\Chrome Dev` has no `NativeMessagingHosts`. |

On Windows the wrapper is `~\.claude\chrome\chrome-native-host.bat`. On 2026-11-13 it pinned
the Claude desktop app's bundled `claude-code\2.1.321\…\claude.exe`, not
`~\.local\bin\claude.exe` (2.1.325). Whichever Claude Code last ran `--chrome` writes it.
`diagnose.ts` does not cover Windows. Check over SSH with `pwsh -NoProfile -Command -` and
a script on stdin; nested quoting through `ssh` breaks.

The `stable-not-linked` verdict prints the commands. In order:

1. Delete a manifest **link** in Chrome Dev's folder that points into the stable folder.
   Once the folder is linked, it would point at itself.
2. Move the stable folder aside (`<name>.stable-backup`) and link it to Chrome Dev's folder.
3. `claude --chrome -p ok` writes the manifest through the link (tested on the Mac
   2026-11-13: deleted, recreated in Chrome Dev's folder, link intact).
4. Restart Chrome Dev: it reads manifests at startup.

The link also holds up for other apps that write manifests for "Chrome". The Claude
desktop app's `com.anthropic.claude_browser_extension.json` showed up in Chrome Dev's
folder the same way.

## The faults

The script names them. Fix only what it names.

### `version-drift`

The wrapper `~/.claude/chrome/chrome-native-host` runs a different `claude` than the
launcher, or one an update removed. Since 2.1.243, Claude Code writes the launcher path
(`exec ~/.local/bin/claude --chrome-native-host`), which survives updates. That holds on
the Mac. On the devbox it still pins a version, even when run as `~/.local/bin/claude --chrome`
(seen 2026-11-13 with 2.1.325). A guess, not checked: there `$HOME` is `/home/max.coplan`, a
link to `/data00/home/max.coplan`, and the launcher check compares the two. So on the devbox,
after any `claude --chrome`, edit the last line by hand:

```sh
exec "$HOME/.local/bin/claude" --chrome-native-host
```
Never point it at a `claude` found on `PATH`: under cmux it is a shim in a temporary folder.
Then retire hosts still running the old binary (below).

### `stable-not-linked`

See the setup section above.

### `no-manifest`

Run `claude --chrome -p ok`. The `/chrome` menu does not write it: **"Install Chrome
extension" only opens the Web Store link.**

### `stale-hosts` / `orphan-sockets`

Hosts from an older version still hold the sockets:

```bash
pkill -f 'chrome-native-host'
rm -f /tmp/claude-mcp-browser-bridge-$(id -un)/*.sock
```

Chrome respawns a host on demand, usually not instantly, so don't wait in a polling loop.

### `no-extension`

Install from <https://claude.ai/chrome> in Chrome Dev.

### Headless Chrome Dev (devbox): signed out after every restart

`diagnose.ts` does not detect this. Symptoms: after Chrome restarts, the browser drops out
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

Confirm with a real tool call in a throwaway headless session:

```bash
cd ~ && claude --chrome -p \
  'Call mcp__claude-in-chrome__list_connected_browsers and print the raw result.' \
  --allowedTools 'mcp__claude-in-chrome__list_connected_browsers'
```

A JSON array of browsers means the integration works. `--allowedTools` matters: without it
the headless run stalls on a permission prompt that has no one to answer it. Creating or
navigating tabs hits a per-session permission grant the user clicks inside the extension.
That gate is normal, not a fault.

## Signals that lie

| Signal | Reality |
|---|---|
| `Extension: Not detected` | Detection scans the stable folder, so without the folder link it is a permanent false negative for Chrome Dev. With the link it says `Installed`, and *Manage permissions* / *Reconnect extension* stop being greyed out (seen on the Mac 2026-11-13). |
| `Browser: <name>` | The signal that matters. It appears, with `Select browser…`, only when a browser is really connected. |
| The startup banner "Claude in Chrome extension detected" | A different code path from the `/chrome` panel, and the more accurate of the two. |
| `Status: Disabled` | Real: run `claude --chrome`, or flip `Enabled by default` in `/chrome`. |

## Environment traps

- **BSD tools reject GNU long flags.** On macOS `pgrep --full` and `pkill --full` match
  nothing while looking like they worked. Use `-f`, flags before the pattern.
- **Do not `grep` for `chrome-native-host` alone** when hunting processes: it matches your
  own shell command and invents a stale host. Require the executable to be a claude binary.
- **Driving a nested Claude Code in tmux**: piping its output through `tee` breaks the TTY.
  Use `tmux capture-pane`, or better the headless `-p` check above.

## When none of the above fits

The client is one large bundled binary. Reading it is a legitimate last resort:

```bash
BIN=$(readlink ~/.local/bin/claude)
rg -a -o '.{0,80}NativeMessagingHosts.{0,80}' "$BIN" | sort -u   # where it writes manifests, per OS
rg -a -o 'chrome-extension://[a-p]{32}' "$BIN" | sort -u         # expected extension id
```

`rg -a` is required: the binary is ~290 MB and is otherwise skipped as binary.

If you confirm a genuine upstream gap (for example, `claude --chrome` ignoring Chrome
channels), file it with `/feedback` from a **non-git scratch directory**: `/feedback`
attaches git metadata from the launch directory. Choose "this session only" for the
transcript, and prefer a freshly spawned session.
