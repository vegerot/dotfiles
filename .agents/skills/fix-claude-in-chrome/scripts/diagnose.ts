// Read-only diagnosis of the Claude in Chrome native-messaging pipe.
// Makes no changes. Prints a verdict with the exact repair commands.
// Run: bun diagnose.ts
import { accessSync, constants, existsSync, lstatSync, readdirSync, readFileSync, readlinkSync, statSync } from "node:fs"
import { homedir, userInfo } from "node:os"
import { basename } from "node:path"

const HOME = homedir()
const EXT_ID_DEFAULT = "fcoeoabgfenejglbffodgkkbkcdhcgfn"
const MANIFEST_NAME = "com.anthropic.claude_code_browser_extension.json"

const ok = (text: string) => console.log(`  ✅ ${text}`)
const bad = (text: string) => console.log(`  ❌ ${text}`)
const info = (text: string) => console.log(`  ·  ${text}`)
const heading = (text: string) => console.log(`\n\x1b[1m${text}\x1b[0m`)

const faults: string[] = []
const fault = (name: string) => faults.push(name)

const tilde = (path: string) => (path.startsWith(HOME) ? "~" + path.slice(HOME.length) : path)
const isFile = (path: string) => existsSync(path) && statSync(path).isFile()
const isDirectory = (path: string) => existsSync(path) && statSync(path).isDirectory()
const isExecutable = (path: string) => {
  try {
    accessSync(path, constants.X_OK)
    return true
  } catch {
    return false
  }
}
// Where a symlink points (one level), or the path itself when it is not a link.
const linkTarget = (path: string) => (lstatSync(path).isSymbolicLink() ? readlinkSync(path) : path)
// Quote a path for pasting into a shell, like bash's printf %q.
const shellQuote = (text: string) => text.replace(/[^A-Za-z0-9_\/.:@%+=,-]/g, "\\$&")

// ---------------------------------------------------------------- launcher
heading("1. Launcher and installed versions")

const pathLauncher = Bun.which("claude")
// A cmux/tmux shim in a temp dir is not the real launcher; prefer the stable one.
const stableLauncher = [`${HOME}/.local/bin/claude`, `${HOME}/.claude/local/claude`].find(isExecutable)

if (stableLauncher) {
  ok(`stable launcher: ${tilde(stableLauncher)} -> ${basename(linkTarget(stableLauncher))}`)
} else {
  bad("no stable launcher at ~/.local/bin/claude or ~/.claude/local/claude")
  fault("no-launcher")
}
if (pathLauncher && pathLauncher !== stableLauncher) {
  info(`PATH claude is a shim: ${tilde(pathLauncher)} (cmux/tmux wrapper — do not pin to it)`)
}

// ------------------------------------------------------------ host wrapper
heading("2. Native host wrapper")

const wrapper = `${HOME}/.claude/chrome/chrome-native-host`
let wrapperTarget = ""
if (isFile(wrapper)) {
  wrapperTarget = readFileSync(wrapper, "utf8").match(/^exec "([^"]*)"/m)?.[1] ?? ""
  if (isExecutable(wrapper)) {
    ok("exists and is executable")
  } else {
    bad("exists but is NOT executable")
    fault("wrapper-not-exec")
  }
  info(`execs: ${tilde(wrapperTarget)}`)

  if (!existsSync(wrapperTarget)) {
    bad("that binary is GONE — the pinned version was removed by an update")
    fault("version-drift")
  } else if (stableLauncher) {
    // Compare what the wrapper runs against what the user runs.
    const wrapperRuns = linkTarget(wrapperTarget)
    const launcherRuns = linkTarget(stableLauncher)
    if (wrapperRuns === launcherRuns) {
      ok("matches the launcher version")
      if (wrapperTarget.includes("/versions/")) info("pinned to an exact version — will drift on the next update")
      else ok("points at the launcher symlink — survives updates")
    } else {
      bad(`VERSION DRIFT: wrapper runs ${basename(wrapperRuns)}, launcher runs ${basename(launcherRuns)}`)
      fault("version-drift")
    }
  }
} else {
  bad("missing — 'claude --chrome' has never generated it")
  fault("no-wrapper")
}

// --------------------------------------------------------- browser catalog
heading("3. Browser directories, manifests and extension")

const appSupport = `${HOME}/Library/Application Support`
const config = `${HOME}/.config`
const browserDirs =
  process.platform === "darwin"
    ? [
        "Google/Chrome", "Google/Chrome Beta", "Google/Chrome Dev", "Google/Chrome Canary", "Chromium",
        "BraveSoftware/Brave-Browser", "BraveSoftware/Brave-Browser-Beta",
        "Microsoft Edge", "Microsoft Edge Beta", "Microsoft Edge Dev",
        "Arc/User Data", "Vivaldi", "com.operasoftware.Opera",
      ].map((name) => `${appSupport}/${name}`)
    : [
        "google-chrome", "google-chrome-beta", "google-chrome-unstable", "chromium",
        "BraveSoftware/Brave-Browser", "microsoft-edge", "microsoft-edge-dev", "vivaldi", "opera",
      ].map((name) => `${config}/${name}`)
// "Profile 1", "Profile 2", ... macOS privacy protection can refuse to list a
// browser's directory (EPERM, seen for Google Chrome); then only Default is checked.
const numberedProfiles = (browserDir: string) => {
  try {
    return readdirSync(browserDir).filter((name) => name.startsWith("Profile "))
  } catch {
    return []
  }
}
const manifestOf = (browserDir: string) => `${browserDir}/NativeMessagingHosts/${MANIFEST_NAME}`

// The manifest names the extension it trusts. Prefer that over a hardcoded ID.
const extensionId =
  browserDirs
    .map(manifestOf)
    .filter(isFile)
    .map((manifest) => readFileSync(manifest, "utf8").match(/chrome-extension:\/\/([a-p]{32})/)?.[1])
    .find(Boolean) ?? EXT_ID_DEFAULT
info(`extension id: ${extensionId}`)

const row = (browser: string, manifest: string, extension: string) =>
  console.log(`  ${browser.padEnd(34)} ${manifest.padEnd(10)} ${extension}`)
console.log()
row("BROWSER", "MANIFEST", "EXTENSION")

let manifestSource = ""
const extensionBrowsers: string[] = []
const manifestBrowsers: string[] = []
for (const browserDir of browserDirs.filter(isDirectory)) {
  const manifest = manifestOf(browserDir)
  const hasManifest = existsSync(manifest)
  if (hasManifest) {
    manifestBrowsers.push(browserDir)
    // A real file (not a symlink) is the source others can link to.
    if (!manifestSource && lstatSync(manifest).isFile()) manifestSource = manifest
  }

  const hasExtension = ["Default", ...numberedProfiles(browserDir)].some((profile) => isDirectory(`${browserDir}/${profile}/Extensions/${extensionId}`))
  if (hasExtension) extensionBrowsers.push(browserDir)

  const label = tilde(browserDir).replace("Library/Application Support/", "").replace(".config/", "")
  row(label, hasManifest ? "✅ yes" : "—", hasExtension ? "✅ installed" : "—")
}

console.log()
if (extensionBrowsers.length === 0) {
  bad("extension not installed in ANY browser")
  fault("no-extension")
}
if (manifestBrowsers.length === 0) {
  bad("manifest written nowhere")
  fault("no-manifest")
}

// The core bug: manifest and extension must live in the SAME browser.
const unserved = extensionBrowsers.filter((browserDir) => !existsSync(manifestOf(browserDir)))
if (unserved.length > 0) {
  for (const browserDir of unserved) bad(`has the extension but NO manifest: ${tilde(browserDir)}`)
  fault("manifest-wrong-browser")
} else if (extensionBrowsers.length > 0) {
  ok("every browser holding the extension also has the manifest")
}

// ----------------------------------------------------------- live processes
heading("4. Running hosts and bridge sockets")

// Match only real hosts: the executable itself must be a claude binary or the
// wrapper. A plain text match also matches this script's own process, which
// would fake a "stale process" fault and send you chasing a repair you do not need.
const hosts = Bun.spawnSync(["ps", "-eo", "pid,command"])
  .stdout.toString()
  .split("\n")
  .filter((line) => line.includes("--chrome-native-host") && line.trim().split(/\s+/)[1]?.includes("claude"))
if (hosts.length > 0) {
  for (const host of hosts) info(`host: ${host.slice(0, 100)}`)
  if (wrapperTarget && !hosts.some((host) => host.includes(wrapperTarget))) {
    bad("a running host uses a DIFFERENT binary than the wrapper — stale process")
    fault("stale-hosts")
  }
} else {
  info("no host running (normal — Chrome spawns one on demand)")
}

const isAlive = (pid: number) => {
  try {
    process.kill(pid, 0)
    return true
  } catch {
    return false
  }
}
const bridgeName = `claude-mcp-browser-bridge-${userInfo().username}`
const socketDir = [`${process.env.TMPDIR ?? "/tmp"}/${bridgeName}`, `/tmp/${bridgeName}`].find(isDirectory)
if (socketDir) {
  const sockets = readdirSync(socketDir).filter((name) => name.endsWith(".sock")).sort()
  let orphans = false
  for (const socket of sockets) {
    if (isAlive(Number(basename(socket, ".sock")))) {
      info(`socket ${socket} — live`)
    } else {
      bad(`socket ${socket} — ORPHAN, owning process is dead`)
      orphans = true
    }
  }
  if (orphans) fault("orphan-sockets")
} else {
  info("no socket dir yet")
}

// ------------------------------------------------------------------ verdict
heading("VERDICT")

if (faults.length === 0) {
  console.log("  Healthy. Nothing to repair.")
  console.log("  Ignore 'Extension: Not detected' in /chrome — see SKILL.md, it lies on non-stable channels.")
  console.log("  Confirm for real with the headless check in SKILL.md rather than trusting the panel.")
  process.exit(0)
}

console.log(`  Faults: ${faults.join(" ")}\n`)
for (const name of faults) {
  switch (name) {
    case "version-drift":
    case "no-wrapper":
      console.log(`  • Wrapper is stale or missing. Regenerate, then unpin it so updates stop breaking it:
        claude --chrome                       # regenerates the wrapper
        # then edit ~/.claude/chrome/chrome-native-host so the last line reads:
        #   exec "$HOME/.local/bin/claude" --chrome-native-host`)
      break
    case "no-manifest":
      console.log("  • No manifest anywhere. Run: claude --chrome   (the /chrome menu will NOT write it)")
      break
    case "manifest-wrong-browser":
      console.log("  • Manifest is in the wrong browser. Link it into each browser listed above:")
      for (const browserDir of unserved) {
        const hostsDir = shellQuote(`${browserDir}/NativeMessagingHosts`)
        console.log(`        mkdir -p ${hostsDir} && ln -sf ${shellQuote(manifestSource || "<run claude --chrome first>")} ${hostsDir}/`)
      }
      console.log("    A symlink, not a copy, so it tracks whatever claude --chrome regenerates.")
      break
    case "stale-hosts":
    case "orphan-sockets":
      console.log("  • Retire stale hosts so Chrome respawns them through the new wrapper:")
      console.log("        pkill -f 'chrome-native-host'   # BSD pkill: -f, never --full")
      console.log(`        rm -f ${socketDir}/*.sock`)
      break
    case "no-extension":
      console.log("  • Install the Claude extension from https://claude.ai/chrome in the browser you actually use.")
      break
    case "wrapper-not-exec":
      console.log(`  • chmod +x ${wrapper}`)
      break
    case "no-launcher":
      console.log("  • Reinstall Claude Code so ~/.local/bin/claude exists.")
      break
  }
}
process.exit(1)
