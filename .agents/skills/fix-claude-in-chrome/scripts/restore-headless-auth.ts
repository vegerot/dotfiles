// Re-sign-in the Claude extension in a headless Chrome after a restart.
//
//   node restore-headless-auth.ts [cdp-port]      # default port 9222; Node >= 22.18 runs .ts directly
//
// Why: the extension keeps its tokens in chrome.storage.session, which Chrome clears on
// restart. Desktop browsers recover through a silent claude.ai sign-in that needs the
// claude.ai login cookie; a headless browser has none (claude.ai's Cloudflare check blocks
// HeadlessChrome), so it stays signed out. The extension also keeps a refresh token on disk
// (chrome.storage.local `diskRefreshToken`); this script does the extension's own refresh
// with it, inside the extension's service worker, over the Chrome DevTools Protocol (CDP).
//
// Chrome must be running with --remote-debugging-port=<cdp-port>.

const EXTENSION_ID = "fcoeoabgfenejglbffodgkkbkcdhcgfn";
const base = `http://127.0.0.1:${process.argv[2] ?? "9222"}`;

type Target = { id: string; type: string; url: string; webSocketDebuggerUrl: string };

declare const chrome: any; // only exists where restore() runs: the extension service worker

// Runs inside the extension service worker. Mirrors the extension's refresh request and the
// storage keys its sign-in writes (session: tokens; local: rotated diskRefreshToken).
async function restore() {
  const session = await chrome.storage.session.get("accessToken");
  if (session.accessToken) return { ok: true, skipped: "already signed in" };
  const { diskRefreshToken: disk, tokenOrg } = await chrome.storage.local.get(["diskRefreshToken", "tokenOrg"]);
  if (!disk?.refreshToken) return { ok: false, why: "no diskRefreshToken: sign in again first" };
  const r = await fetch("https://platform.claude.com/v1/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      client_id: "dae2cad8-15c5-43d2-9046-fcaecc135fa4", // the extension's production OAuth client
      refresh_token: disk.refreshToken,
      expires_in: "31536000", // what the extension requests
    }),
  });
  const j = await r.json().catch(() => ({}));
  if (!j.access_token) return { ok: false, status: r.status, error: j.error ?? j };
  // Refresh tokens rotate: persist the new one, or the next restore fails with invalid_grant.
  const refreshToken = j.refresh_token ?? disk.refreshToken;
  const accountUuid = j.account?.uuid ?? disk.accountUuid;
  await chrome.storage.local.set({
    diskRefreshToken: { refreshToken, accountUuid },
    ...(j.scope && { tokenScope: j.scope }),
  });
  await chrome.storage.session.set({
    accessToken: j.access_token,
    refreshToken,
    tokenExpiry: Date.now() + 1000 * j.expires_in,
    tokenOrgUuid: j.organization?.uuid?.toLowerCase() ?? tokenOrg?.uuid,
  });
  await chrome.storage.session.remove("startupReauthState");
  return { ok: true, account: j.account?.email_address, expiresInHours: Math.round(j.expires_in / 3600) };
}

async function targets(): Promise<Target[]> {
  return (await fetch(`${base}/json/list`)).json();
}

async function findWorker(): Promise<Target | undefined> {
  return (await targets()).find(
    (t) => t.type === "service_worker" && t.url.startsWith(`chrome-extension://${EXTENSION_ID}/`),
  );
}

// An idle Manifest V3 service worker is not a CDP target; opening an extension page wakes it.
async function wakeWorker(): Promise<Target> {
  const page: Target = await (
    await fetch(`${base}/json/new?${encodeURIComponent(`chrome-extension://${EXTENSION_ID}/options.html`)}`, { method: "PUT" })
  ).json();
  try {
    for (let i = 0; i < 20; i++) {
      const worker = await findWorker();
      // A just-woken worker is listed slightly before its extension APIs exist.
      if (worker && (await evaluate(worker.webSocketDebuggerUrl, "typeof chrome").catch(() => "")) === "object") return worker;
      await new Promise((r) => setTimeout(r, 500));
    }
    throw new Error("extension service worker did not start: is the Claude extension installed and enabled?");
  } finally {
    await fetch(`${base}/json/close/${page.id}`);
  }
}

async function evaluate(wsUrl: string, expression: string): Promise<unknown> {
  const ws = new WebSocket(wsUrl);
  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = reject;
  });
  const reply: any = await new Promise((resolve) => {
    ws.onmessage = (m) => {
      const msg = JSON.parse(String(m.data));
      if (msg.id === 1) resolve(msg); // workers send events (Inspector.workerScriptLoaded) first
    };
    ws.send(JSON.stringify({ id: 1, method: "Runtime.evaluate", params: { expression, awaitPromise: true, returnByValue: true } }));
  });
  ws.close();
  if (reply.result?.exceptionDetails) throw new Error(JSON.stringify(reply.result.exceptionDetails));
  return reply.result?.result?.value;
}

const worker = (await findWorker()) ?? (await wakeWorker());
const result: any = await evaluate(worker.webSocketDebuggerUrl, `(${restore.toString()})()`);
console.log(JSON.stringify(result, null, 2));
process.exit(result?.ok ? 0 : 1);
