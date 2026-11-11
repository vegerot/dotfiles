#!/usr/bin/env node
// Copy bytedcli's ByteCloud SSO cookies into the devbox headless Chrome.
// Usage: inject-bytecloud-cookies.mjs [--isolated-test URL]
//   --isolated-test URL  load the cookies into a throwaway browser context,
//                        open URL there, and print where it ends up.
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';

const cookieFile = `${homedir()}/.local/share/bytedcli/data/bytecloud_session.json`;
const debugAddress = 'http://127.0.0.1:9222';
const testUrl = process.argv[2] === '--isolated-test' ? process.argv[3] : undefined;

const cookies = JSON.parse(readFileSync(cookieFile, 'utf8')).cookies.map((cookie) => ({
  name: cookie.name,
  value: cookie.value,
  // CDP treats a domain without a leading dot as host-only.
  domain: cookie.hostOnly ? cookie.domain : `.${cookie.domain.replace(/^\./, '')}`,
  path: cookie.path,
  secure: cookie.secure,
  httpOnly: cookie.httpOnly,
  ...(cookie.sameSite ? { sameSite: cookie.sameSite[0].toUpperCase() + cookie.sameSite.slice(1).toLowerCase() } : {}),
  ...(cookie.expiresAt ? { expires: cookie.expiresAt / 1000 } : {}),
}));

const { webSocketDebuggerUrl } = await (await fetch(`${debugAddress}/json/version`)).json();
const socket = new WebSocket(webSocketDebuggerUrl);
await new Promise((resolve) => socket.addEventListener('open', resolve));
let nextId = 0;
const pending = new Map();
socket.addEventListener('message', (event) => {
  const message = JSON.parse(event.data);
  pending.get(message.id)?.(message);
});
const send = (method, params = {}, sessionId) =>
  new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, (message) => (message.error ? reject(new Error(`${method}: ${message.error.message}`)) : resolve(message.result)));
    socket.send(JSON.stringify({ id, method, params, sessionId }));
  });

let browserContextId;
if (testUrl) ({ browserContextId } = await send('Target.createBrowserContext'));
await send('Storage.setCookies', { cookies, browserContextId });
console.log(`set ${cookies.length} cookies${testUrl ? ' in a throwaway context' : ' in the default profile'}`);

if (testUrl) {
  const { targetId } = await send('Target.createTarget', { url: testUrl, browserContextId });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  await new Promise((resolve) => setTimeout(resolve, 15000));
  const evaluate = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true }, sessionId)).result.value;
  console.log('final URL:', await evaluate('location.href'));
  console.log('title:', await evaluate('document.title'));
  await send('Target.disposeBrowserContext', { browserContextId });
}
socket.close();
