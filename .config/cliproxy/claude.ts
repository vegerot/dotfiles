// Generate Claude Code's picker from the same chat catalog as Pi and OpenCode.
import { mkdtemp, rm, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { fetchCatalog, PROXY_URL, PROXY_KEY } from "./catalog"

const models = await fetchCatalog(new AbortController().signal)
if (!models.length) throw new Error("CLIProxyAPI returned no chat models")
const directory = await mkdtemp(join(tmpdir(), "claude-proxy-"))
const settings = join(directory, "settings.json")
await writeFile(settings, JSON.stringify({
  modelPicker: {
    replaceBuiltInOptions: true,
    options: models.map((model) => ({
      model: model.id,
      label: model.name,
      description: `${model.owner || "CLIProxyAPI"} · ${model.context ? `${Math.round(model.context / 1000)}K context` : "context unspecified"}`,
    })),
  },
  model: "GPT-6.1-Sol-Max",
}))
try {
  const child = Bun.spawn(["claude", "--settings", settings, ...process.argv.slice(2)], {
    stdin: "inherit", stdout: "inherit", stderr: "inherit",
    env: {
      ...process.env,
      ANTHROPIC_BASE_URL: PROXY_URL.replace(/\/v1\/?$/, ""),
      ANTHROPIC_AUTH_TOKEN: PROXY_KEY,
      ...(process.argv.includes("--bare") ? { ANTHROPIC_API_KEY: PROXY_KEY } : {}),
      // The generated picker already filters media, hidden routes, and Standard duplicates.
      CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY: "0",
      ANTHROPIC_DEFAULT_OPUS_MODEL: "claude-opus-5-5-high",
      ANTHROPIC_DEFAULT_SONNET_MODEL: "claude-sonnet-5-5-high",
      ANTHROPIC_DEFAULT_HAIKU_MODEL: "Seed-2.1-Turbo",
    },
  })
  process.exitCode = await child.exited
} finally {
  await rm(directory, { recursive: true })
}
