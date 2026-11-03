---
name: lark-browser-send
description: Send Lark or Feishu messages through Lark Messenger in the browser, with Claude in Chrome when it is available and otherwise Chrome DevTools MCP or the `chrome-devtools` CLI, including real mentions and thread replies. Recover browser access by sharing a fresh native-app authorization link or sign-in QR code with the user and resume sending after approval. Use whenever the user asks to send a Lark message.  Do not use `lark-im` for sending messages.
---

# Send messages through Lark Messenger

Complete the user's requested send through the browser. Start with the existing session; request sign-in or device authorization only when the actual page requires it. Keep the requested recipient, thread, message, and mentions across authorization so the user does not need to repeat the task.

## Open the existing session and try the send

- Choose the browser driver in this order. Read [browser recipes](references/browser-recipes.md) for each driver's steps, editor insertion, authentication-link extraction, and the experiments supporting this workflow.
  1. **Claude in Chrome**, when `mcp__claude-in-chrome__*` tools exist. It drives the user's real, signed-in Chrome profile. Each Chrome profile with the extension is a separate connected browser. If several are connected and none is selected, ask the user which one, as `list_connected_browsers` instructs.
  2. **`chrome-devtools` CLI**, or Chrome DevTools MCP tools when only those are exposed. Attach to the running browser as `$chrome-control` describes. `new_page` opens Chrome's default profile, which can be the personal one.
- Lark works only in the work Chrome profile. Another profile just shows an error, so switch to the work profile.
- With Claude in Chrome, open `https://bytedance.larkoffice.com/next/messenger/` in a tab of your own and close it when done. With `chrome-devtools`, reuse an existing Messenger tab or open one in the work profile. Use fresh page IDs, snapshot UIDs, and element refs.
- On Max's devbox, the authenticated profile is `~/.cache/sa-tea-chrome-profile`. Prefer the configured browser or running debugging endpoint. A default CLI browser can have a different profile: inspect this before treating a missing session as a need to sign in. Do not restart a shared browser just to switch profiles.
- Find the requested chat or person through Search. Verify the opened chat header, distinguishing search results mentioning a person from that person's direct chat. Open the requested thread before composing a reply. Do not substitute a different chat or create an unrelated top-level message.
- Compose the authorized message and select any requested mentions from the actual picker. Inspect the complete draft after the editor has updated. Send once, then verify the message in the chat or thread.

Use an existing authorized send request directly; do not ask for another confirmation. If the recipient or message is genuinely missing, ask for that information.

## Recover access when required

Inspect the page to distinguish these states:

**Messenger is usable:** continue the requested send without an authorization detour.

**Partial Messenger shell:** a title and Search label with an empty main area do not prove a working session or a sign-in failure. Allow initialization to finish, take another snapshot, and try one reload. Inspect console errors if necessary. In the verified sessions the UI eventually loaded despite console errors. Stop and report a persistent loading failure instead of repeatedly reloading or asking for unrelated device approval.

**Signed in, but device authorization required:** the page says `Access denied` and offers `Authorize in Feishu App`. Click that specific button and capture the fresh HTTPS `applink.larkoffice.com/client/security/bind_device` URL created in a hidden iframe or new tab. The recipe filters for a new matching iframe rather than assuming the last iframe is the link. Preserve the complete URL and query string; do not reconstruct it or reuse an older challenge.

Share the fresh link as a clickable link and ask the user to open it in Feishu/Lark and approve authorization for this browser. Keep the original blocked tab and profile. Wait for the user's approval; elapsed time is not approval. After they say it is done, reload the original tab and verify actual chat UI access, then resume the original send. If the challenge expires, generate a new link on the same page. A link opening successfully is not proof that Messenger is authorized.

**Not signed in:** follow the actual sign-in page. If it exposes a native-app authorization link, share that fresh link for the user to approve. If it offers a QR code, capture and show the current QR image with its app instructions, and ask the user to scan and approve it. The clean-session experiment showed a QR-only Feishu login page; do not promise a device-binding link for every login. Keep the login tab alive. After sign-in, return to Messenger and handle device authorization if that separate gate appears.

Keep transient authorization links and QR images out of committed records and reusable examples. The user completes native-app approval; do not click approval on their behalf.

## Compose and verify

- The message composer is a contenteditable editor. On November 2, 2026 it held one `div.ace-line` row per line; earlier sessions saw a Slate editor. Choose the visible editor in the intended chat/thread, focus it, and use real typing or paste events. Direct `innerHTML`/`textContent` writes can miss editor state.
- Search opens a modal whose focus lands on the modal wrapper, not the input. Click the input itself before typing.
- For full multiline text, use the paste recipe. It preserves newlines and literal quotes, backticks, dollar signs, Unicode, and emoji. Read the draft in a separate step after the event; the immediate script return can still contain the old text. Check line structure by reading the `.ace-line` rows: `innerText` showed extra blank lines at the end (zero-width spaces) that were not rows.
- For a real mention, enter `@`, select the exact person or bot from the picker, and verify a mention node. Plain `@name` text is insufficient. The historical MR !4459 bot was `bytedcli 历史 MR 处理`; choose the recipient requested for the current task instead of assuming that bot name.
- Preserve an existing draft. Do not overwrite it without resolving what should happen to it. Clear only drafts created during your own experiments.
- Before sending, verify the destination, full text, required mentions, and thread placement. Preserve user-written message text. Apply the applicable attribution rule when composing text on the user's behalf.
- Prefer the actual Send control or the configured send shortcut. The Send button sits at the composer's bottom right (tooltip `Send (Enter)`), and the composer footer says `Shift + Enter to add a new line`. A focused-editor Enter event also worked in the historical session; inspect the current UI rather than assuming that behavior everywhere.
- Verify a new outgoing message containing the intended text in the correct conversation, with the composer back to its placeholder and no failed/pending indicator. A recipient acknowledgment is extra evidence, not a requirement. An Enter call or a cleared composer alone does not establish delivery. The read-only `lark-cli im +chat-messages-list --as user --user-id <open_id>` (or `--chat-id`) is an independent delivery check.
- If sending has an ambiguous outcome, inspect the conversation before retrying to avoid duplicate messages. Report confirmed delivery or the concrete failure, including any outstanding user authorization.
- This being a web UI, it's subject to change and be buggy.  Experiment with better ways to do things and if one is discovered, ask the user for permission to update this skill.
