const TRAE_URL = "https://copilot-cn.bytedance.net/api/ide/v2/llm_raw_chat"
const TRAE_APP_ID = "6eefa01c-1036-4c7e-9ca5-d891f63bfcd8"
const REFRESH_TIMEOUT_MS = 15_000
const USER_HOME = Bun.env.HOME
if (!USER_HOME) throw new Error("HOME is not set")

type CachedModel = Readonly<{
  slug: string
  config_name?: string
  context_window?: number
  output_tokens_hard_limit?: number
  visibility?: string
  supported_in_api?: boolean
  input_modalities?: ReadonlyArray<string>
  default_reasoning_level?: string | null
  supported_reasoning_levels?: ReadonlyArray<Readonly<{ effort: string }>>
  business_metadata?: Readonly<{
    variants?: Readonly<{
      standard_key?: string
      standard_context_window?: number
      max_key?: string | null
      max_context_window?: number | null
      backend_token_limits?: Readonly<
        Record<string, Readonly<{ input_tokens?: number; output_tokens?: number }>>
      >
    }>
  }>
}>

export type ModelRoute = Readonly<{
  name: string
  config: string
  backend: string
  context: number
  output: number
  reasoning: ReadonlyArray<string>
  input: ReadonlyArray<"text" | "image">
}>

export type ChatMessage = Readonly<{
  role: string
  content?: string | null | ReadonlyArray<Readonly<Record<string, unknown>>>
  reasoning_content?: string
  tool_calls?: ReadonlyArray<
    Readonly<{
      id?: string
      type?: string
      function?: Readonly<{ name?: string; arguments?: string }>
    }>
  >
  tool_call_id?: string
}>

export type ChatRequest = Readonly<{
  model: string
  messages: ReadonlyArray<ChatMessage>
  tools?: ReadonlyArray<Readonly<Record<string, unknown>>>
  parallel_tool_calls?: boolean
  max_tokens?: number
  max_completion_tokens?: number
  reasoning_effort?: string
}>

type TraeEvent = Readonly<Record<string, unknown>> &
  Readonly<{
    response?: string | null
    reasoning_content?: string | null
    tool_calls?: ReadonlyArray<
      Readonly<Record<string, unknown>> & Readonly<{ function_call?: Readonly<Record<string, unknown>> }>
    >
    finish_reason?: string
  }>

type CachedCatalog = Readonly<{
  models?: ReadonlyArray<CachedModel>
}>

export const catalog = {
  models: {} as Readonly<Record<string, ModelRoute>>,
  initialization: undefined as Promise<{ refreshed: boolean }> | undefined,
  refresh: undefined as Promise<void> | undefined,
  reloads: new Set<() => Promise<void>>(),
}

export function cachePath() {
  return `${traeHome()}/models_cache.json`
}

export function reasoningVariants(efforts: ReadonlyArray<string>) {
  return efforts.map((effort) => ({ id: effort, settings: { reasoningEffort: effort } }))
}

const DISPLAY_NAMES: Readonly<Record<string, string>> = {
  "openrouter-4o": "Claude Opus 5.5 (openrouter-4o)",
}

const EXCLUDED_SLUGS: ReadonlySet<string> = new Set([
  "openrouter-3o",
  "openrouter-2o",
  "openrouter-1o",
  "openrouter-1",
  "GPT-5.6-Sol",
  "GPT-5.6-Luna",
  "GPT-5.5",
  "GPT-5.4",
  "GPT-5.2",
  "DeepSeek-V4-Flash",
  "Seed-2.1-Pro-0915",
  "Seed-Dogfooding-2.0",
  "Seed-Code",
  "Gemini-3.1-Pro-Preview",
  "Gemini-3-Flash-Preview",
])

export function translateCatalog(catalog: CachedCatalog, path: string) {
  if (!Array.isArray(catalog.models)) throw new Error(`Invalid Trae model cache: ${path}`)

  const loaded: Record<string, ModelRoute> = {}
  for (const model of catalog.models) {
    if (model.visibility !== "list" || model.supported_in_api === false || EXCLUDED_SLUGS.has(model.slug)) continue
    const variants = model.business_metadata?.variants
    if (!model.config_name || !variants?.standard_key || !variants.standard_context_window)
      throw new Error(`Trae cache model ${model.slug} is missing its standard route`)
    const config = model.config_name
    const backend = variants.standard_key
    const context = variants.standard_context_window
    const output = variants.backend_token_limits?.[backend]?.output_tokens ?? model.output_tokens_hard_limit ?? 32_768
    const explicitReasoning = model.supported_reasoning_levels?.map((level) => level.effort) ?? []
    const reasoning =
      explicitReasoning.length > 0
        ? explicitReasoning
        : model.default_reasoning_level
          ? [model.default_reasoning_level]
          : []
    const input = model.input_modalities?.includes("image") ? (["text", "image"] as const) : (["text"] as const)
    const displayName = DISPLAY_NAMES[model.slug] ?? model.slug
    loaded[model.slug] = {
      name: displayName,
      config,
      backend,
      context,
      output,
      reasoning,
      input,
    }

    if (variants.max_key && variants.max_context_window) {
      const id = `${model.slug}-Max`
      loaded[id] = {
        name: `${displayName} / Max`,
        config,
        backend: variants.max_key,
        context: variants.max_context_window,
        output:
          variants.backend_token_limits?.[variants.max_key]?.output_tokens ?? model.output_tokens_hard_limit ?? 32_768,
        reasoning,
        input,
      }
    }
  }
  if (!Object.keys(loaded).length) throw new Error(`Trae model cache has no visible API models: ${path}`)

  return { models: loaded }
}

export async function readCatalog() {
  const path = cachePath()
  return translateCatalog(await Bun.file(path).json(), path)
}

function catalogFingerprint(catalog: Readonly<Record<string, ModelRoute>>) {
  return JSON.stringify(Object.entries(catalog).sort(([left], [right]) => left.localeCompare(right)))
}

async function runTraex(args: ReadonlyArray<string>, purpose: string) {
  const executable = Bun.which("traex")
  if (!executable) throw new Error(`Cannot ${purpose} because \`traex\` is not on PATH`)

  const process = Bun.spawn([executable, ...args], { stdout: "ignore", stderr: "pipe" })
  const stderr = new Response(process.stderr).text()
  let timedOut = false
  const timeout = setTimeout(() => {
    timedOut = true
    process.kill()
  }, REFRESH_TIMEOUT_MS)
  const [exitCode, errorOutput] = await Promise.all([process.exited, stderr])
  clearTimeout(timeout)
  if (timedOut) throw new Error(`Trae ${purpose} timed out after ${REFRESH_TIMEOUT_MS} ms`)
  if (exitCode !== 0) throw new Error(`Trae ${purpose} failed (${exitCode}): ${errorOutput.trim().slice(0, 2_000)}`)
}

export async function refreshCache() {
  await runTraex(["debug", "models", "--remote"], "model refresh")
}

export async function initializeCatalog() {
  catalog.initialization ??= (async () => {
    let refreshed = false
    const snapshot = await readCatalog().catch(async () => {
      await refreshCache()
      refreshed = true
      return readCatalog()
    })
    catalog.models = snapshot.models
    return { refreshed }
  })()
  return catalog.initialization
}

async function refreshCatalog() {
  const previousFingerprint = catalogFingerprint(catalog.models)
  await refreshCache()
  const snapshot = await readCatalog()
  const changed = catalogFingerprint(snapshot.models) !== previousFingerprint
  catalog.models = snapshot.models
  if (changed) await Promise.all([...catalog.reloads].map((reload) => reload()))
}

export function startCatalogRefresh() {
  catalog.refresh ??= refreshCatalog().catch((error) =>
    console.error("Trae model refresh failed; using cached catalog", error),
  )
}

function traeHome() {
  if (Bun.env.TRAECLI_HOME) return Bun.env.TRAECLI_HOME
  return `${Bun.env.TRAE_HOME ?? `${USER_HOME}/.trae`}/cli`
}

async function accessToken() {
  const auth = await Bun.file(`${traeHome()}/auth.json`).json() as Readonly<{ trae?: { access_token?: string } }>
  const token = auth.trae?.access_token
  if (typeof token !== "string" || !token) throw new Error("Trae is not logged in; run `traex login`")
  return token
}

function contentParts(content: ChatMessage["content"]) {
  if (typeof content === "string") return [{ type: "text", text: content }]
  if (!content) return []
  return content
}

export function translateMessages(input: ReadonlyArray<ChatMessage>) {
  return input.map((message) => {
    const reasoningContent =
      message.reasoning_content || (message.role === "assistant" && message.tool_calls?.length ? " " : undefined)
    return {
    role: message.role,
    content: contentParts(message.content),
    ...(reasoningContent ? { reasoning_content: reasoningContent } : {}),
    ...(message.tool_call_id ? { tool_call_id: message.tool_call_id } : {}),
    ...(message.tool_calls
      ? {
          tool_calls: message.tool_calls.map((call, index) => ({
            id: call.id,
            index,
            type: call.type ?? "function",
            function_call: call.function,
          })),
        }
      : {}),
  }
  })
}

export function latestUserInput(input: ReadonlyArray<ChatMessage>) {
  const content = input.findLast((message) => message.role === "user")?.content
  if (typeof content === "string") return content
  if (!Array.isArray(content)) return ""
  return content
    .filter((part) => part.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n")
}

export function translateTools(input: ReadonlyArray<Readonly<Record<string, unknown>>>) {
  return input.map((tool) => {
    if (tool.type !== "function" || typeof tool.function !== "object" || !tool.function) return tool
    const { strict: _, parameters, ...definition } = tool.function as Readonly<Record<string, unknown>>
    return {
      ...tool,
      function: {
        ...definition,
        parameters: typeof parameters === "string" ? parameters : JSON.stringify(parameters ?? {}),
      },
    }
  })
}

export async function refreshAuth() {
  await runTraex(["models"], "authentication refresh")
}

export function shouldRefreshAuth(attempt: number, status: number | undefined) {
  return attempt === 1 && (status === 401 || status === 403)
}

export function buildTraePayload(body: ChatRequest, model: ModelRoute, id: string) {
  return {
    access_type: 4,
    config_name: model.config,
    conversation_id: id,
    extra_info: "",
    is_preset: true,
    max_tokens: body.max_tokens ?? body.max_completion_tokens ?? model.output,
    messages: translateMessages(body.messages),
    model_name: model.backend,
    parallel_tool_calls: body.parallel_tool_calls ?? true,
    ...(body.reasoning_effort ? { reasoning_effort: body.reasoning_effort } : {}),
    session_id: id,
    tools: translateTools(body.tools ?? []),
    user_input: latestUserInput(body.messages),
  }
}

export async function translateRequest(request: Request, url = TRAE_URL) {
  const body = (await request.json()) as ChatRequest
  const model = catalog.models[body.model]
  if (!model) throw new Error(`Unknown Trae model: ${body.model}`)
  return new Request(url, {
    method: "POST",
    signal: request.signal,
    headers: {
      accept: "text/event-stream",
      authorization: `Cloud-CLI-JWT ${await accessToken()}`,
      "content-type": "application/json",
      // A live omission probe confirmed that Trae rejects requests without these three headers.
      "x-app-id": TRAE_APP_ID,
      "x-ide-function": "traecli_next",
      "x-ide-version-code": new Date().toISOString().slice(0, 10).replaceAll("-", ""),
    },
    body: JSON.stringify(buildTraePayload(body, model, crypto.randomUUID())),
  })
}

function chunk(model: string, delta: Readonly<Record<string, unknown>>, finishReason: string | null = null) {
  return JSON.stringify({
    id: `chatcmpl-${crypto.randomUUID()}`,
    object: "chat.completion.chunk",
    created: Math.floor(Date.now() / 1_000),
    model,
    choices: [{ index: 0, delta, finish_reason: finishReason }],
  })
}

// Grok's chat-completions decoder requires `id` on every SSE chunk, including the usage trailer.
function usageChunk(model: string, usage: Readonly<Record<string, unknown>>) {
  return JSON.stringify({
    id: `chatcmpl-${crypto.randomUUID()}`,
    object: "chat.completion.chunk",
    created: Math.floor(Date.now() / 1_000),
    model,
    choices: [],
    usage,
  })
}

export function translateFinishReason(reason: string | null | undefined) {
  if (reason === "tool_use" || reason === "function_call") return "tool_calls"
  if (reason === "max_tokens") return "length"
  return reason || "stop"
}

function translate(eventName: string, event: TraeEvent, model: string) {
  if (eventName === "output") {
    const delta = {
      ...(typeof event.response === "string" && event.response ? { content: event.response } : {}),
      ...(typeof event.reasoning_content === "string" && event.reasoning_content
        ? { reasoning_content: event.reasoning_content }
        : {}),
      ...(event.tool_calls?.length
        ? {
            tool_calls: event.tool_calls.map((call, index) => ({
              index: typeof call.index === "number" ? call.index : index,
              id: call.id,
              type: "function",
              function: call.function_call,
            })),
          }
        : {}),
    }
    if (Object.keys(delta).length) return `data: ${chunk(model, delta)}\n\n`
  }
  if (eventName === "token_usage") {
    return `data: ${usageChunk(model, {
      prompt_tokens: event.prompt_tokens,
      completion_tokens: event.completion_tokens,
      total_tokens: event.total_tokens,
      prompt_tokens_details: {
        cached_tokens: event.cache_read_input_tokens ?? 0,
        cache_write_tokens: event.cache_creation_input_tokens ?? 0,
      },
      completion_tokens_details: { reasoning_tokens: event.reasoning_tokens ?? 0 },
    })}\n\n`
  }
  if (eventName === "done") {
    return `data: ${chunk(model, {}, translateFinishReason(event.finish_reason))}\n\ndata: [DONE]\n\n`
  }
  if (eventName === "error") {
    const message = typeof event.message === "string" ? event.message : JSON.stringify(event)
    return `data: ${JSON.stringify({ error: { message } })}\n\n`
  }
  return ""
}

export function translatedStream(response: Response, model: string) {
  const reader = response.body!.getReader()
  const decoder = new TextDecoder()
  const encoder = new TextEncoder()
  let buffer = ""
  let cancelled = false
  const processBlock = (block: string, controller: ReadableStreamDefaultController<Uint8Array>) => {
    const eventName = block.match(/^event:\s*(.+)$/m)?.[1] ?? ""
    const data = block
      .split(/\r?\n/)
      .filter((line) => line.startsWith("data:"))
      .map((line) => line.slice(5).trimStart())
      .join("\n")
    if (!data) return
    if (eventName === "progress_notice") {
      controller.enqueue(encoder.encode(`: ${data}\n\n`))
      return
    }
    const output = translate(eventName, JSON.parse(data), model)
    if (output) controller.enqueue(encoder.encode(output))
  }
  return new ReadableStream<Uint8Array>({
    async start(controller) {
      try {
        while (true) {
          const value = await reader.read()
          if (value.done) break
          buffer += decoder.decode(value.value, { stream: true })
          const blocks = buffer.split(/\r?\n\r?\n/)
          buffer = blocks.pop() ?? ""
          for (const block of blocks) processBlock(block, controller)
        }
        if (cancelled) return
        buffer += decoder.decode()
        if (buffer.trim()) processBlock(buffer, controller)
        controller.close()
      } catch (error) {
        if (!cancelled) controller.error(error)
      }
    },
    async cancel(reason) {
      cancelled = true
      await reader.cancel(reason).catch(() => {})
    },
  })
}

export function translateResponse(response: Response, model: string) {
  if (!response.ok || !response.body) return response
  return new Response(translatedStream(response, model), {
    status: response.status,
    headers: { "cache-control": "no-cache", "content-type": "text/event-stream" },
  })
}

