import { watch } from "node:fs"
import { dirname } from "node:path"
import {
  type ModelRoute,
  cachePath,
  catalog,
  initializeCatalog,
  readCatalog,
  refreshAuth,
  shouldRefreshAuth,
  startCatalogRefresh,
  translateRequest,
  translateResponse,
} from "./provider"

const BEGIN_MARKER = "# BEGIN TRAE OPENAI-COMPATIBILITY"
const END_MARKER = "# END TRAE OPENAI-COMPATIBILITY"
const DEFAULT_PORT = Number(Bun.env.TRAE_OPENAI_PORT ?? "43821")
const DEFAULT_CONFIG_PATH = Bun.env.CLIPROXY_CONFIG ?? "/opt/homebrew/etc/cliproxyapi.conf"

export function renderCliProxyBlock(models: Readonly<Record<string, ModelRoute>>, baseURL: string) {
  const flowList = (items: ReadonlyArray<string>) => `[${items.map((item) => JSON.stringify(item)).join(", ")}]`
  const lines = [
    BEGIN_MARKER,
    "api-keys:",
    "  openai-compatibility:",
    '    - name: "trae"',
    `      base-url: ${JSON.stringify(baseURL)}`,
    "      keys:",
    '        - api-key: "trae-local"',
    "      models:",
  ]
  for (const [id, info] of Object.entries(models)) {
    lines.push(
      `        - name: ${JSON.stringify(id)}`,
      `          alias: ${JSON.stringify(id)}`,
      `          display-name: ${JSON.stringify(info.name)}`,
      `          max-context-length: ${info.context}`,
      `          input-modalities: ${flowList(info.input)}`,
      '          output-modalities: ["text"]',
      "          is-compat: true",
      "          thinking:",
      `            levels: ${flowList(info.reasoning)}`,
    )
  }
  lines.push(END_MARKER)
  return lines.join("\n")
}

export function updateCliProxyConfigText(
  currentText: string,
  models: Readonly<Record<string, ModelRoute>>,
  baseURL: string,
) {
  const block = renderCliProxyBlock(models, baseURL)
  const start = currentText.indexOf(BEGIN_MARKER)
  const end = currentText.indexOf(END_MARKER)
  if (start !== -1 && end !== -1 && end > start) {
    return `${currentText.slice(0, start)}${block}${currentText.slice(end + END_MARKER.length)}`
  }
  const trimmed = currentText.replace(/\s+$/, "")
  return `${trimmed}\n\n${block}\n`
}

export async function syncCliProxyConfig(
  configPath: string,
  models: Readonly<Record<string, ModelRoute>>,
  baseURL: string,
) {
  const file = Bun.file(configPath)
  if (!(await file.exists())) return false
  const current = await file.text()
  const updated = updateCliProxyConfigText(current, models, baseURL)
  if (updated === current) return false
  await Bun.write(configPath, updated)
  return true
}

async function assembleChatCompletion(sseResponse: Response, model: string) {
  const text = await sseResponse.text()
  let id = `chatcmpl-${crypto.randomUUID()}`
  let created = Math.floor(Date.now() / 1_000)
  let content = ""
  let reasoning = ""
  let finishReason = "stop"
  let usage: Record<string, unknown> | undefined
  const toolCalls = new Map<number, { id: string; type: "function"; function: { name: string; arguments: string } }>()

  for (const line of text.split(/\r?\n/)) {
    if (!line.startsWith("data:")) continue
    const payload = line.slice(5).trim()
    if (!payload || payload === "[DONE]") continue
    const frame = JSON.parse(payload) as Record<string, any>
    if (frame.error) {
      return Response.json(frame, { status: 502 })
    }
    if (typeof frame.id === "string") id = frame.id
    if (typeof frame.created === "number") created = frame.created
    if (frame.usage) usage = frame.usage

    const choice = frame.choices?.[0]
    if (!choice) continue
    if (typeof choice.finish_reason === "string") finishReason = choice.finish_reason

    const delta = choice.delta
    if (!delta) continue
    if (typeof delta.content === "string") content += delta.content
    if (typeof delta.reasoning_content === "string") reasoning += delta.reasoning_content
    if (Array.isArray(delta.tool_calls)) {
      for (const tc of delta.tool_calls) {
        const idx = typeof tc.index === "number" ? tc.index : 0
        const existing = toolCalls.get(idx) ?? {
          id: tc.id ?? `call_${idx}`,
          type: "function" as const,
          function: { name: "", arguments: "" },
        }
        if (tc.id) existing.id = tc.id
        if (tc.function?.name) existing.function.name = tc.function.name
        if (typeof tc.function?.arguments === "string") existing.function.arguments += tc.function.arguments
        toolCalls.set(idx, existing)
      }
    }
  }

  const orderedToolCalls = [...toolCalls.entries()].sort(([a], [b]) => a - b).map(([, call]) => call)
  return Response.json({
    id,
    object: "chat.completion",
    created,
    model,
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content: orderedToolCalls.length > 0 && !content ? null : content,
          ...(reasoning ? { reasoning_content: reasoning } : {}),
          ...(orderedToolCalls.length > 0 ? { tool_calls: orderedToolCalls } : {}),
        },
        finish_reason: finishReason,
      },
    ],
    ...(usage ? { usage } : {}),
  })
}

export type TraeHandlerOptions = Readonly<{
  getModels?: () => Readonly<Record<string, ModelRoute>>
  buildUpstreamRequest?: (request: Request) => Promise<Request>
  onRefreshAuth?: () => Promise<void>
}>

export function createTraeHandler(options: TraeHandlerOptions = {}) {
  const getModels = options.getModels ?? (() => catalog.models)
  const buildUpstreamRequest = options.buildUpstreamRequest ?? ((req: Request) => translateRequest(req))
  const onRefreshAuth = options.onRefreshAuth ?? refreshAuth

  return async function handle(req: Request): Promise<Response> {
    const url = new URL(req.url)
    if (req.method === "GET" && url.pathname === "/healthz") {
      return Response.json({ ok: true, models: Object.keys(getModels()).length })
    }
    if (req.method === "GET" && (url.pathname === "/v1/models" || url.pathname === "/models")) {
      const now = Math.floor(Date.now() / 1_000)
      return Response.json({
        object: "list",
        data: Object.entries(getModels()).map(([id, info]) => ({
          id,
          object: "model",
          created: now,
          owned_by: "trae",
          context_window: info.context,
          max_completion_tokens: info.output,
          input_modalities: info.input,
          reasoning_levels: info.reasoning,
        })),
      })
    }
    if (req.method === "POST" && (url.pathname === "/v1/chat/completions" || url.pathname === "/chat/completions")) {
      try {
        const rawBody = await req.text()
        const parsed = JSON.parse(rawBody) as { model: string; stream?: boolean }
        const makeReq = () =>
          buildUpstreamRequest(
            new Request(req.url, {
              method: "POST",
              headers: { "content-type": "application/json" },
              body: rawBody,
              signal: req.signal,
            }),
          )

        let upstream = await fetch(await makeReq())
        if (shouldRefreshAuth(1, upstream.status)) {
          await onRefreshAuth()
          upstream = await fetch(await makeReq())
        }
        if (!upstream.ok) {
          const errText = await upstream.text()
          return Response.json(
            { error: { message: `Trae upstream HTTP ${upstream.status}: ${errText}`, type: "upstream_error" } },
            { status: upstream.status },
          )
        }
        const sseResp = translateResponse(upstream, parsed.model)
        if (parsed.stream !== true) {
          return await assembleChatCompletion(sseResp, parsed.model)
        }
        return sseResp
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error)
        return Response.json({ error: { message, type: "server_error" } }, { status: 500 })
      }
    }
    return Response.json({ error: { message: `Not found: ${req.method} ${url.pathname}` } }, { status: 404 })
  }
}

if (import.meta.main) {
  const baseURL = `http://127.0.0.1:${DEFAULT_PORT}/v1`
  const sync = async () => {
    await syncCliProxyConfig(DEFAULT_CONFIG_PATH, catalog.models, baseURL)
  }
  const initial = await initializeCatalog()
  catalog.reloads.add(sync)
  await sync()
  if (!initial.refreshed) startCatalogRefresh()

  try {
    const targetPath = cachePath()
    watch(dirname(targetPath), async (_event, filename) => {
      if (filename && filename !== "models_cache.json") return
      try {
        const snapshot = await readCatalog()
        catalog.models = snapshot.models
        await sync()
      } catch {
        // Ignore transient write states while traex updates models_cache.json
      }
    })
  } catch {
    // Directory watch is optional
  }

  const handler = createTraeHandler()
  Bun.serve({
    hostname: "127.0.0.1",
    port: DEFAULT_PORT,
    idleTimeout: 255,
    fetch(req, server) {
      server.timeout(req, 0)
      return handler(req)
    },
  })
  console.log(`Trae OpenAI-compatible server listening on ${baseURL} (${Object.keys(catalog.models).length} models)`)
}
