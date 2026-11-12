// Tests for claude-recap-title. They run the script the way Claude Code does:
// hook JSON on stdin, a fixture transcript on disk, and they read stdout.
// The only fake is `claude` itself (the call to Haiku), replaced by a stub on PATH.
// Run: bun test bin/claude-recap-title.test.ts
import { beforeEach, expect, test } from "bun:test"
import { appendFileSync, chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

const script = join(import.meta.dir, "claude-recap-title")
let tmp: string
let transcript: string

beforeEach(() => {
  tmp = mkdtempSync(join(tmpdir(), "claude-recap-title-"))
  transcript = join(tmp, "transcript.jsonl")
  // Stub namer: records each call and its stdin, then prints a fixed title.
  mkdirSync(join(tmp, "bin"))
  writeFileSync(
    join(tmp, "bin/claude"),
    `#!/usr/bin/env bun
import { appendFileSync } from "node:fs"
appendFileSync("${tmp}/namer-stdin", await Bun.stdin.text())
appendFileSync("${tmp}/namer-calls", "call\\n")
await Bun.sleep(Number(process.env.STUB_SLEEP ?? 0) * 1000)
console.log(process.env.STUB_TITLE ?? "Recap title hook")
process.exit(Number(process.env.STUB_EXIT ?? 0))
`,
  )
  chmodSync(join(tmp, "bin/claude"), 0o755)
})

// Run the script with the hook input Claude Code sends; resolves to its stdout.
const hook = async (mode: "generate" | "apply", env: Record<string, string> = {}) => {
  const input = { session_id: "session-1", transcript_path: transcript, hook_event_name: "UserPromptSubmit", prompt: "next prompt" }
  const child = Bun.spawn([script, mode], {
    stdin: Buffer.from(JSON.stringify(input)),
    stderr: "inherit",
    env: { ...process.env, XDG_STATE_HOME: join(tmp, "state"), PATH: `${tmp}/bin:${process.env.PATH}`, ...env },
  })
  return (await new Response(child.stdout).text()).trimEnd()
}

// Transcript lines, as Claude Code writes them.
const append = (line: object) => appendFileSync(transcript, JSON.stringify(line) + "\n")
const recap = (uuid: string, text: string) =>
  append({ type: "system", subtype: "away_summary", content: text, uuid, sessionId: "session-1" })
const typedRecap = (uuid: string, text: string) =>
  append({ type: "system", subtype: "local_command", content: `<local-command-stdout>${text}</local-command-stdout>`, uuid, commandRun: { command: "recap", args: "" } })
const automaticTitle = (title: string) => append({ type: "ai-title", aiTitle: title, sessionId: "session-1" })
const customTitle = (title: string) => append({ type: "custom-title", customTitle: title, sessionId: "session-1" })

// The hook output that sets the session title.
const titleJson = (title: string) => `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"${title}"}}`
const namerCalls = () => (existsSync(`${tmp}/namer-calls`) ? readFileSync(`${tmp}/namer-calls`, "utf8").split("\n").filter(Boolean).length : 0)
const namerStdin = () => readFileSync(`${tmp}/namer-stdin`, "utf8").trimEnd().split("\n")

test("apply prints nothing when no name is pending", async () => {
  expect(await hook("apply")).toBe("")
})

test("after a recap, apply prints the name as the session title", async () => {
  recap("recap-1", "Building a hook that renames the session after each recap. Next: wire it into settings.")
  await hook("generate")
  expect(await hook("apply")).toBe(titleJson("Recap title hook"))
})

test("a name is applied only once", async () => {
  recap("recap-1", "Building a hook.")
  await hook("generate")
  await hook("apply")
  expect(await hook("apply")).toBe("")
})

test("a recap is named only once", async () => {
  recap("recap-1", "Building a hook.")
  await hook("generate")
  await hook("generate")
  expect(namerCalls()).toBe(1)
})

test("a session without a recap is not named", async () => {
  append({ type: "user", message: { role: "user", content: "hello there" }, uuid: "u1" })
  await hook("generate")
  expect(namerCalls()).toBe(0)
})

test("a newer recap gets a name too, from its own text", async () => {
  recap("recap-1", "Building a hook.")
  await hook("generate")
  await hook("apply")
  recap("recap-2", "Planning a winter trip.")
  await hook("generate")
  expect(await hook("apply")).toBe(titleJson("Recap title hook"))
  expect(namerStdin().at(-1)).toBe("Planning a winter trip.")
})

test("the namer's own prompt does not start another naming", async () => {
  recap("recap-1", "Building a hook.")
  // The namer is itself a `claude` run, so it fires this hook again with the marker variable set.
  await hook("generate", { CLAUDE_RECAP_TITLE_NAMING: "1" })
  expect(namerCalls()).toBe(0)
})

test("a failed naming sets no title", async () => {
  recap("recap-1", "Building a hook.")
  await hook("generate", { STUB_TITLE: "" })
  expect(await hook("apply")).toBe("")
})

test("a second prompt during naming does not name again", async () => {
  recap("recap-1", "Building a hook.")
  const first = hook("generate", { STUB_SLEEP: "1" })
  await Bun.sleep(300) // the first naming is now in flight
  await hook("generate")
  await first
  expect(namerCalls()).toBe(1)
})

test("an error message from the namer is not used as a title", async () => {
  recap("recap-1", "Building a hook.")
  await hook("generate", { STUB_TITLE: "Not logged in · Please run /login", STUB_EXIT: "1" })
  expect(await hook("apply")).toBe("")
})

test("a typed /recap is named too, without its tags", async () => {
  recap("recap-1", "Building a hook.")
  typedRecap("recap-2", "Baking sourdough bread.")
  await hook("generate")
  expect(await hook("apply")).toBe(titleJson("Recap title hook"))
  expect(namerStdin().at(-1)).toBe("Baking sourdough bread.")
})

test("the namer is told the current title", async () => {
  automaticTitle("Prompt cache explanation")
  recap("recap-1", "Baking sourdough bread.")
  await hook("generate")
  expect(namerStdin()[0]).toBe("Current name: Prompt cache explanation")
})

test("a custom title is the current title even when the automatic one is written later", async () => {
  automaticTitle("Prompt cache explanation")
  customTitle("Sourdough timing")
  automaticTitle("Prompt cache explanation") // Claude Code writes the automatic title again from time to time
  recap("recap-1", "Baking sourdough bread.")
  await hook("generate")
  expect(namerStdin()[0]).toBe("Current name: Sourdough timing")
})

test("an unchanged name is not applied again", async () => {
  customTitle("Sourdough timing")
  recap("recap-1", "Baking sourdough bread, still.")
  await hook("generate", { STUB_TITLE: "Sourdough timing" })
  expect(await hook("apply")).toBe("")
})
