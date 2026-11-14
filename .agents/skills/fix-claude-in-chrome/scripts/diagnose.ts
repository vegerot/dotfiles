// Read-only diagnosis of the Claude in Chrome native-messaging pipe, for Chrome Dev.
// Makes no changes. Prints a verdict with the exact repair commands.
// Run: bun diagnose.ts
import { accessSync, constants, existsSync, lstatSync, readdirSync, readFileSync, readlinkSync, realpathSync, statSync } from "node:fs"
import { homedir, userInfo } from "node:os"
import { basename, dirname } from "node:path"

const HOME = homedir()
const EXT_ID_DEFAULT = "fcoeoabgfenejglbffodgkkbkcdhcgfn"
const MANIFEST_NAME = "com.anthropic.claude_code_browser_extension.json"

if (process.platform === "win32") {
  // claude --chrome writes HKCU\Software\Google\Chrome\NativeMessagingHosts, and every
  // Chrome channel reads that same hardcoded key (Chromium launch_context_win.cc).
  console.log("Windows: Chrome Dev reads the key claude --chrome writes. Nothing to link; this script checks Mac and Linux only.")
  process.exit(0)
}

const ok = (text: string) => console.log(`  ✅ ${text}`)
const bad = (text: string) => console.log(`  ❌ ${text}`)
const info = (text: string) => console.log(`  ·  ${text}`)
const heading = (text: string) => console.log(`\n\x1b[1m${text}\x1b[0m`)

const faults: string[] = []
const fault = (name: string) => faults.push(name)

const tilde = (path: string) => (path.startsWith(HOME) ? "~" + path.slice(HOME.length) : path)
const isDirectory = (path: string) => existsSync(path) && statSync(path).isDirectory()
const isExecutable = (path: string) => {
  try {
    accessSync(path, constants.X_OK)
    return true
  } catch {
    return false
  }
}
const isSymlink = (path: string) => {
  try {
    return lstatSync(path).isSymbolicLink()
  } catch {
    return false
  }
}
// Where a symlink points (one level), or the path itself when it is not a link.
const linkTarget = (path: string) => (isSymlink(path) ? readlinkSync(path) : path)
// Quote a path for pasting into a shell, like bash's printf %q.
const shellQuote = (text: string) => text.replace(/[^A-Za-z0-9_\/.:@%+=,-]/g, "\\$&")

// claude --chrome writes only to the stable folder. Chrome reads <user data dir>/NativeMessagingHosts.
// So the stable folder must be a link to Chrome Dev's.
const [stableDir, devDir] =
  process.platform === "darwin"
    ? [`${HOME}/Library/Application Support/Google/Chrome`, `${HOME}/Library/Application Support/Google/Chrome Dev`]
    : [`${HOME}/.config/google-chrome`, `${HOME}/.config/google-chrome-unstable`]

// ---------------------------------------------------------------- launcher
heading("1. Launcher")

// A cmux/tmux shim in a temp dir is not the real launcher; prefer the stable one.
const launcher = [`${HOME}/.local/bin/claude`, `${HOME}/.claude/local/claude`].find(isExecutable)
if (launcher) {
  ok(`${tilde(launcher)} -> ${basename(linkTarget(launcher))}`)
} else {
  bad("no launcher at ~/.local/bin/claude or ~/.claude/local/claude")
  fault("no-launcher")
}

// ------------------------------------------------------------ host wrapper
heading("2. Native host wrapper")

const wrapper = `${HOME}/.claude/chrome/chrome-native-host`
let wrapperTarget = ""
if (existsSync(wrapper)) {
  // `exec /abs/path/claude --chrome-native-host`, quoted or not, maybe with $HOME.
  wrapperTarget = (readFileSync(wrapper, "utf8").match(/^exec "?([^"\s]+)"?/m)?.[1] ?? "").replace(/^\$HOME/, HOME)
  info(`execs: ${tilde(wrapperTarget)}`)
  if (!isExecutable(wrapper)) {
    bad("NOT executable")
    fault("wrapper-not-exec")
  }
  if (!existsSync(wrapperTarget)) {
    bad("that binary is GONE — an update removed the pinned version")
    fault("version-drift")
  } else if (launcher && realpathSync(wrapperTarget) !== realpathSync(launcher)) {
    bad(`VERSION DRIFT: wrapper runs ${basename(realpathSync(wrapperTarget))}, launcher runs ${basename(realpathSync(launcher))}`)
    fault("version-drift")
  } else {
    ok(wrapperTarget.includes("/versions/") ? "matches the launcher today, but pinned to a version" : "follows the launcher")
  }
} else {
  bad("missing — 'claude --chrome' has never run here")
  fault("no-wrapper")
}

// ------------------------------------------------------------- Chrome Dev
heading("3. Chrome Dev")

const devManifest = `${devDir}/NativeMessagingHosts/${MANIFEST_NAME}`
if (!isDirectory(devDir)) {
  bad(`no Chrome Dev data at ${tilde(devDir)}`)
  fault("no-chrome-dev")
} else {
  ok(`data: ${tilde(devDir)}`)

  if (isSymlink(stableDir) && realpathSync(stableDir) === realpathSync(devDir)) {
    ok(`${tilde(stableDir)} is a link to it, so claude --chrome writes here`)
  } else {
    bad(`${tilde(stableDir)} is ${existsSync(stableDir) ? "a real folder" : "missing"}, not a link to Chrome Dev`)
    fault("stable-not-linked")
  }

  if (existsSync(devManifest)) {
    ok(`manifest present${isSymlink(devManifest) ? ` (link -> ${tilde(readlinkSync(devManifest))})` : ""}`)
  } else {
    bad(isSymlink(devManifest) ? "manifest is a DANGLING link" : "manifest missing")
    fault("no-manifest")
  }

  // The manifest names the extension it trusts. Prefer that over a hardcoded ID.
  const extensionId = existsSync(devManifest)
    ? (readFileSync(devManifest, "utf8").match(/chrome-extension:\/\/([a-p]{32})/)?.[1] ?? EXT_ID_DEFAULT)
    : EXT_ID_DEFAULT
  const profiles = ["Default", ...readdirSync(devDir).filter((name) => name.startsWith("Profile "))]
  const withExtension = profiles.filter((profile) => isDirectory(`${devDir}/${profile}/Extensions/${extensionId}`))
  if (withExtension.length > 0) {
    ok(`extension ${extensionId} in: ${withExtension.join(", ")}`)
  } else {
    bad(`extension ${extensionId} not installed in any Chrome Dev profile`)
    fault("no-extension")
  }
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
  console.log("  Confirm for real with the headless check in SKILL.md rather than trusting the /chrome panel.")
  process.exit(0)
}

console.log(`  Faults: ${faults.join(" ")}\n`)
for (const name of faults) {
  switch (name) {
    case "version-drift":
    case "no-wrapper":
      console.log("  • Regenerate the wrapper from the launcher (not from a versioned path):")
      console.log(`        ${tilde(launcher ?? "~/.local/bin/claude")} --chrome -p ok`)
      console.log(`    If it pins a version again (seen on the devbox), make its last line:`)
      console.log(`        exec "$HOME/.local/bin/claude" --chrome-native-host`)
      break
    case "stable-not-linked": {
      // A manifest link into the stable folder would point at itself once the folder is linked.
      const parent = shellQuote(dirname(stableDir))
      console.log("  • Link the stable folder to Chrome Dev's (one time per machine):")
      if (isSymlink(devManifest)) console.log(`        rm ${shellQuote(devManifest)}`)
      if (existsSync(stableDir)) console.log(`        mv ${shellQuote(stableDir)} ${shellQuote(stableDir)}.stable-backup`)
      console.log(`        ln -s ${shellQuote(basename(devDir))} ${parent}/${shellQuote(basename(stableDir))}`)
      console.log("        claude --chrome -p ok        # rewrites the manifest through the link")
      console.log("    Then restart Chrome Dev: it reads manifests at startup.")
      break
    }
    case "no-manifest":
      if (!faults.includes("stable-not-linked")) console.log("  • Run: claude --chrome -p ok   (the /chrome menu will NOT write it)")
      break
    case "stale-hosts":
    case "orphan-sockets":
      console.log("  • Retire stale hosts so Chrome respawns them through the wrapper:")
      console.log("        pkill -f 'chrome-native-host'   # BSD pkill: -f, never --full")
      console.log(`        rm -f ${socketDir}/*.sock`)
      break
    case "no-extension":
      console.log("  • Install the Claude extension in Chrome Dev from https://claude.ai/chrome")
      break
    case "no-chrome-dev":
      console.log("  • Install Chrome Dev, or on a headless box pass --user-data-dir with the path above.")
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
