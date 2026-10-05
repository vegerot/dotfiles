---
name: gws-gotchas
description: Hard-won, verified notes for running the Google Workspace CLI (`gws`) on macOS — auth state, shell behavior, Drive/Docs/Sheets import quirks, and Chrome DevTools integration. Read this BEFORE using `gws` (alongside the upstream `gws-shared` skill).
---

# gws on this machine (macOS)

Everything below was observed and verified in practice. Re-verify with `gws auth status` if needed.

## Setup state
- `gws` v0.22.5 installed with `npm install -g @googleworkspace/cli`.
- Binary: `/opt/homebrew/bin/gws`.
- Signed in as `max.k.coplan@gmail.com` with **broad access (granted 2026-10-04, verified by `gws auth status` and live Drive/Gmail API calls)**: Drive, Docs, Sheets, Slides, Tasks, Calendar, Contacts, Forms (body + responses read), Chat (messages, spaces), Meet (`meetings.space.created`), Pub/Sub, `cloud-platform`, and **full Gmail (`https://mail.google.com/`, includes permanent delete)**, plus openid/email/profile.
- **Google Keep is NOT available**: the scope `https://www.googleapis.com/auth/keep` is rejected with `invalid_scope` for personal Gmail (Keep API is Workspace-only). Do not request it.
- `gws auth login --full` only requests 9 services, which is too narrow. The login uses a custom list of full URLs: `--scopes "https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/documents,https://www.googleapis.com/auth/spreadsheets,https://www.googleapis.com/auth/presentations,https://www.googleapis.com/auth/tasks,https://www.googleapis.com/auth/calendar,https://www.googleapis.com/auth/contacts,https://www.googleapis.com/auth/forms.body,https://www.googleapis.com/auth/forms.responses.readonly,https://www.googleapis.com/auth/chat.messages,https://www.googleapis.com/auth/chat.spaces,https://www.googleapis.com/auth/meetings.space.created,https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/cloud-platform,https://mail.google.com/,openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/userinfo.profile"`.
- Revoke access any time: `gws auth logout` or https://myaccount.google.com/permissions.
- OAuth client: Desktop app "gws CLI" in GCP project `gen-lang-client-0002673038` ("AI Coding"). Client file: `~/.config/gws/client_secret.json`. Credentials are encrypted in `~/.config/gws/credentials.enc` (key in macOS Keychain via keyring backend).
- **Publishing status is "In production"** in GCP (set 2026-10-04). This prevents tokens from expiring after 7 days (the default for External apps in Testing mode). The app is unverified (warning screen at login, 100-user cap), which is expected for personal developer tools.
- Check health: `gws auth status` (look for `token_valid: true` and `has_refresh_token: true`).
- Output starts with `Using keyring backend: keyring`; parse JSON from the first `{` when parsing stdout.

## Shell & CLI usage
- Unlike Windows PowerShell, macOS zsh passes JSON strings cleanly:
  `gws drive files list --params '{"pageSize": 5}'` works directly.
- In Node or scripts, `child_process.execFileSync("gws", ["drive", "files", "list", "--params", JSON.stringify({pageSize: 5})])` is safe and bypasses shell escaping entirely.
- `--upload` paths must be **relative to the current working directory**.
- `drive files delete` writes a stray `download.html` into the current working directory. Run it from a scratch directory, never from a git repo root.

## Drive / Docs / Sheets behavior
- **Markdown becomes a real Google Doc**: `gws drive files create --upload x.md --upload-content-type text/markdown --json '{"name":..,"mimeType":"application/vnd.google-apps.document","parents":[..]}'`.
- **Updating an existing Doc from Markdown**: `gws drive files update --upload x.md --upload-content-type text/markdown --params '{"fileId":..}'` converts and replaces the content while preserving the document ID.
- `drive files generateIds` IDs are **rejected for Docs** ("Generated IDs are not supported for Docs Editors formats"). To know a Doc's URL before filling it, create it empty first, then update it.
- **xlsx -> Google Sheet**: upload with `mimeType: application/vnd.google-apps.spreadsheet` and content-type `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`.
- Sheets: write with `valueInputOption: RAW` and convert currency strings yourself, then apply number formatting. `USER_ENTERED` turns cells like `Dec 31` into dates.
- Native Sheets charts can be created via API (`addChart` in `spreadsheets batchUpdate`).

## What only the browser can do
- **Embedding a live Sheets chart in a Doc** has no API. Use Chrome (Chrome DevTools MCP / `chrome-devtools` CLI): place cursor, then Insert -> Chart -> From Sheets -> double-click the Sheet tile -> select chart -> keep "Link to spreadsheet" -> Import.
- In the Docs canvas, Ctrl+F / Cmd+F finds text, but text deletion or rich canvas interactions may require Docs API batchUpdate (`replaceAllText`).

## Browser connection (Chrome Dev)
- Chrome Dev remote debugging runs on `http://127.0.0.1:9222`.
- `chrome-devtools start --autoConnect --channel=dev` runs a persistent daemon.
- MCP server is configured in `~/.gemini/config/mcp_config.json` with `command: "chrome-devtools-mcp"`, `args: ["--auto-connect", "--channel=dev"]`.
