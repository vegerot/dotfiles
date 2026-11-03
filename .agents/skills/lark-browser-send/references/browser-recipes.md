# Browser recipes and evidence

Read this for each driver's steps, or when editor/authentication mechanics need inspection. Selectors below were observed, so inspect the current DOM and snapshot before using them.

## Claude in Chrome (preferred)

Observed November 2, 2026 in Claude Code on the work MacBook. Load the tools in one ToolSearch: `list_connected_browsers`, `select_browser`, `tabs_context_mcp`, `navigate`, `computer`, `javascript_tool`, `find`, `read_page`, `browser_batch`, `tabs_close_mcp`.

1. `list_connected_browsers` lists each Chrome profile that has the extension. That session listed `Personal Chrome - work laptop` and `Browser 2`; `Browser 2` was the work profile. Lark shows an error in any other profile.
2. `navigate` to `https://bytedance.larkoffice.com/next/messenger/`. Without a `tabId` it creates this session's tab group. Grey skeleton rows showed for about 3 seconds. Wait, then take a scaled screenshot (`scale: 0.6`).
3. Click `Search (⌘+K)` in the left sidebar. The modal (`One search, find everything.`) left focus on its wrapper (`larklet-modal-wrapper`), so `document.execCommand('insertText')` reported nothing focused. Click the input itself, then `computer` `type` the query. A Chinese name typed correctly.
4. Person results show the name and department. Group results below them say `Includes: <name>`. Click the person row for a direct chat, then check the header name and the recent history.
5. Click the composer (placeholder `Communicate responsibly. Ensure message is publicly acceptable.`) and run the paste function below in `javascript_tool`. The code is a tool parameter, so no shell quoting is involved. First throw if `document.activeElement` is not contenteditable or already holds a draft.
6. Check the rows (below), click the Send button at the composer's bottom right (tooltip `Send (Enter)`), wait about 3 seconds, and screenshot. Then close the tab with `tabs_close_mcp`.

Chain predictable steps with `browser_batch`, for example click, type, wait, screenshot. Coordinates always use the full-resolution frame, even when the screenshot was scaled.

Check the draft's line structure from the editor rows, not `innerText`, which showed extra trailing blank lines made of zero-width spaces:

```javascript
[...document.activeElement.querySelectorAll('.ace-line')]
  .map(row => row.innerText.replaceAll(String.fromCharCode(0x200b), ''))
```

## CLI and browser profile

```bash
command -v chrome-devtools
chrome-devtools status
chrome-devtools list_pages
chrome-devtools take_snapshot <page-id>
chrome-devtools evaluate_script '<JavaScript function>' --pageId <page-id>
```

Use each command's `--help` for the installed version. Array flags use separate values, e.g. `--resourceTypes xhr fetch`, not a comma-separated string.

For other questions, reference ~/code/github.com/ChromeDevTools/chrome-devtools-mcp/

When a debugging endpoint is already running and the CLI daemon is unused, attach with:

```bash
chrome-devtools start --browserUrl=http://127.0.0.1:9222
```

When no shared browser is running, Max's authenticated profile can be launched with:

```bash
chrome-devtools start \
  --channel=dev \
  --headless=true \
  --userDataDir=/home/max.coplan/.cache/sa-tea-chrome-profile \
  --usageStatistics=false
```

`start` can restart the CLI daemon: inspect who is using it first. Keep the same profile and tab through authorization. Launching an isolated context is useful for a sign-in experiment, but loses the existing session and is inappropriate for the normal send.

On macOS, attach to the running Chrome Dev with `--autoConnect --channel=dev` as `$chrome-control` describes. On November 2, 2026 a `list_pages` run with no daemon auto-started an isolated one (`status` showed `args=["--viaCli"]`). Stop that one and start again before using the browser.

`new_page` opened Chrome's default profile, which was the personal profile on the work MacBook. To open Messenger in the work profile, inject a temporary `<a target="_blank">` into a tab already open in the work profile. Click its snapshot `uid` with `chrome-devtools click`, which is a trusted gesture, so the popup blocker allows it. Remove the link afterwards. This worked for internal consoles in October 2026 but has not been tried for Messenger.

## Search and real mentions

Click Search using a fresh snapshot UID. `.appNavbar-search-input` was its observed DOM container in September 2026. By November 2026 Search opened a modal that left focus on its wrapper; click the modal's input first. Focus the visible search editor, then insert a query with:

```javascript
() => {
  const e = document.activeElement;
  if (!e?.isContentEditable) throw Error('Search editor is not focused');
  return document.execCommand('insertText', false, 'CURRENT SEARCH QUERY');
}
```

Take another snapshot to verify the query; wait for results and select the correct result. Displayed names can be split across multiple snapshot text nodes.

In the chat composer, type `@`, wait for suggestions, and click the intended suggestion. Observed selectors were `.mention-suggestion` and `.mention-suggestion_name`. Verify the exact name in a `contenteditable="false"` mention node inside the composer. Do not select a same-named message author elsewhere on the page.

## Paste full text without shell interpolation

With Claude in Chrome, run only the `browserFunction` body as an immediately invoked function in `javascript_tool`, with the message as a JavaScript string literal. With the CLI, run this JavaScript with Bun. Use an argument array to pass message text and JavaScript as literal arguments. Set the current page ID and message deliberately. Focus and verify the correct composer before this call; do not assume the first contenteditable belongs to the destination.

```javascript
const pageId = 2; // Replace with the current page ID.
const message = "First line\nSecond line";
const browserFunction = `() => {
  const e = document.activeElement;
  if (!e?.isContentEditable) throw Error('Composer is not focused');
  const data = new DataTransfer();
  data.setData('text/plain', ${JSON.stringify(message)});
  e.dispatchEvent(new ClipboardEvent('paste', {
    clipboardData: data, bubbles: true, cancelable: true
  }));
  return 'Paste dispatched; verify the updated draft separately';
}`;
const result = Bun.spawnSync({
  cmd: ['chrome-devtools', 'evaluate_script', browserFunction,
    '--pageId', String(pageId)],
  stdout: 'inherit',
  stderr: 'inherit',
});
if (result.exitCode !== 0) {
  throw new Error(`chrome-devtools exited with code ${result.exitCode}`);
}
```

Take a fresh snapshot afterward. The editor update is asynchronous: an `innerText` read immediately after paste returned the old placeholder in the live experiment, while the subsequent snapshot contained all three lines correctly.

When editing an existing sent message (`contextmenu` → `Edit Message`), `document.execCommand('selectAll')` only selects the first paragraph in Slate; clear the edit box with `chrome-devtools press_key <pageId> "Meta+a"` (or `"Control+a"`) and `"Backspace"` before pasting, then click the `Save` button by snapshot UID.

## Extract a fresh device authorization link

Run this on the actual device-denial page. It clicks the named button and waits up to two seconds for a new matching iframe URL. If none appears, inspect new tabs and the DOM instead of inventing a link.

```javascript
async () => {
  const before = new Set([...document.querySelectorAll('iframe')].map(f => f.src));
  const button = [...document.querySelectorAll('button')]
    .find(b => b.innerText.trim() === 'Authorize in Feishu App');
  if (!button) throw Error('Authorization button missing');
  button.click();
  for (let i = 0; i < 20; i++) {
    const fresh = [...document.querySelectorAll('iframe')].map(f => f.src)
      .filter(src => {
        try {
          const u = new URL(src);
          return !before.has(src) && u.protocol === 'https:' &&
            u.hostname === 'applink.larkoffice.com' &&
            u.pathname === '/client/security/bind_device';
        } catch { return false; }
      });
    if (fresh.length) return fresh.at(-1);
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  throw Error('No fresh device authorization iframe found');
}
```

Send the complete returned URL to the user promptly. After their approval, reload the original blocked tab and verify real chat access before sending.

## QR sign-in

In the clean-session experiment the browser redirected to `accounts.feishu.cn/accounts/page/login` with `Log In With QR Code`. The QR was a canvas inside `.newLogin_scan-QR-code`, absent from the accessibility snapshot. A Chrome DevTools screenshot visibly captured it. Inspect the QR region and capture it at readable resolution, then show the image to the user. Follow the app named on the page. This page exposed no native-app link; the “Switch to Lark to log in” link changed the login provider and was not a device authorization link.

## Evidence and limits

- Authorization conversation `01a0d51f-d6f1-7041-ac1e-5f0098fad21e`, September 24, 2026: signed-in conditional-access denial; button added a fresh hidden `bind_device` iframe; user approved; reload reached Messenger. Archive: `/data00/home/max.coplan/code/github.com/vegerot/ai-conversations/bytedance/lark-web-device-authorization.md`.
- Send conversation `01a0cbf5-f2b6-7912-bde4-43949b487d93`, September 24, 2026: searched `4459`, opened the dedicated MR group, selected the real review-bot mention, pasted a full multiline request, sent with Enter, and observed the outgoing message and bot's `WorkingOnIt` acknowledgment.
- Live experiments September 30, 2026: launched the saved profile, recovered from a partial Messenger shell after reload/initialization, searched for Max Coplan, opened the self chat, pasted three lines with shell-sensitive symbols and Unicode, selected a real self mention, and cleared the experiment draft. No test message was sent.
- A separate isolated context reproduced QR-only sign-in; the QR screenshot was visually inspected, then that context's tab was closed. Device approval was not forced on the already-authorized saved profile. Its completion is established by the historical transcript.
- A controlled DOM fixture with an old binding iframe, a newly generated matching iframe, and an unrelated final iframe verified that the extraction recipe selected the new link. The fixture was cleared afterward. This checks extraction logic, not live authorization completion.
- Send conversation `3361fa2a-2d82-4e2a-a61a-51d1e2114ed2` (Claude Code), November 2, 2026, work MacBook: Claude in Chrome on the work profile. Searched a colleague by Chinese name, opened the direct chat, pasted a nine-line message with an emoji, confirmed nine `.ace-line` rows, sent with the Send button, and confirmed delivery in the chat and with `lark-cli im +chat-messages-list`. The search-modal focus trap and the extra trailing `innerText` lines were observed there.

Note: This being a web UI, it's subject to change and be buggy.  Experiment with better ways to do things and if one is discovered, ask the user for permission to update this skill.
