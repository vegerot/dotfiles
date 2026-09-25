import { createWriteStream, mkdirSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, join } from "node:path"

const HOST = "127.0.0.1"
const PORT = 43821
const TRAE_URL = "https://copilot-cn.bytedance.net/api/ide/v2/llm_raw_chat"
const TRAE_APP_ID = "6eefa01c-1036-4c7e-9ca5-d891f63bfcd8"
const DEBUG = ["1", "true", "yes"].includes((process.env.OPENCODE_TRAE_DEBUG ?? "").toLowerCase())
const LOG_PATH =
  process.env.OPENCODE_TRAE_LOG ?? join(homedir(), ".local", "share", "opencode", "log", "trae-provider.log")

const models = {
  "Seed-Evolving": { config: "Doubao-Seed-Evolving", backend: "Doubao-Seed-Evolving__dev", context: 1_000_000 },
  "Seed-2.1-Pro-0915": { config: "Doubao-Seed-2.1-Pro", backend: "Doubao-Seed-2.1-Pro__dev", context: 200_000 },
  "Seed-2.1-Turbo": { config: "Doubao-Seed-2.1-Turbo", backend: "Doubao-Seed-2.1-Turbo__dev", context: 200_000 },
  "openrouter-2o": { config: "openrouter-2o", backend: "openrouter-2o__dev", context: 200_000 },
  "GPT-6-Astra": { config: "gpt-6-astra", backend: "gpt-6-astra__dev", context: 272_000 },
  "GPT-5.6-Sol": { config: "gpt-5.6-sol", backend: "gpt-5.6-sol__dev", context: 272_000 },
  "GPT-5.6-Terra": { config: "gpt-5.6-terra", backend: "gpt-5.6-terra__dev", context: 272_000 },
  "GPT-5.6-Luna": { config: "gpt-5.6-luna", backend: "gpt-5.6-luna__dev", context: 272_000 },
  "GPT-5.5": { config: "gpt-5.5", backend: "gpt-5.5__dev", context: 272_000 },
  "GPT-5.4": { config: "gpt-5.4", backend: "gpt-5.4__dev", context: 272_000 },
  "DeepSeek-V4-Pro": { config: "DeepSeek-V4-Pro", backend: "DeepSeek-V4-Pro__dev", context: 216_000 },
  "DeepSeek-V4-Flash": { config: "DeepSeek-V4-Flash", backend: "DeepSeek-V4-Flash__dev", context: 216_000 },
  "Seed-Dogfooding-2.0": { config: "Seed-Dogfooding-2.0", backend: "Seed-Dogfooding-2.0__dev", context: 200_000 },
  "Seed-Code": { config: "Doubao-Seed-Code", backend: "Doubao-Seed-Code__dev", context: 116_000 },
  "openrouter-1o": { config: "openrouter-1o", backend: "openrouter-1o__dev", context: 200_000 },
  "openrouter-1": { config: "openrouter-1", backend: "openrouter-1__dev", context: 200_000 },
  "GPT-5.2": { config: "gpt-5.2", backend: "gpt-5.2__dev", context: 272_000 },
  "Gemini-3.1-Pro-Preview": { config: "gemini-3.1-pro", backend: "gemini-3.1-pro__dev", context: 200_000 },
  "Gemini-3-Flash-Preview": { config: "gemini-3-flash", backend: "gemini-3-flash__dev", context: 200_000 },
} as const

type ChatMessage = {
  role: string
  content?: string | null | Array<Record<string, unknown>>
  tool_calls?: Array<{
    id?: string
    type?: string
    function?: { name?: string; arguments?: string }
  }>
  tool_call_id?: string
}

type ChatRequest = {
  model: keyof typeof models
  messages: ChatMessage[]
  tools?: Array<Record<string, unknown>>
  parallel_tool_calls?: boolean
  max_tokens?: number
  max_completion_tokens?: number
}

type TraeEvent = Record<string, unknown> & {
  response?: string | null
  reasoning_content?: string | null
  tool_calls?: Array<Record<string, unknown> & { function_call?: Record<string, unknown> }>
  finish_reason?: string
}

type RequestState = {
  traceID: string
  requestedModel: string
  configName: string
  backendModel: string
  upstreamURL: string
  upstreamStatus?: number
  servedModel?: string
  requestBytes: number
  upstreamBytes: number
  downstreamBytes: number
  eventCount: number
  progressNoticeCount: number
  outputEventCount: number
  startedAt: string
  elapsedMs?: number
  completed?: boolean
  sawDone?: boolean
  error?: ReturnType<typeof errorInfo>
}

let lastRequest: RequestState | undefined
let logStream: ReturnType<typeof createWriteStream> | undefined

function errorInfo(error: unknown, depth = 0): { name: string; message: string; stack?: string; cause?: unknown } {
  if (!(error instanceof Error)) return { name: typeof error, message: String(error) }
  return {
    name: error.name,
    message: error.message,
    ...(error.stack ? { stack: error.stack } : {}),
    ...(error.cause !== undefined && depth < 3 ? { cause: errorInfo(error.cause, depth + 1) } : {}),
  }
}

function log(level: "debug" | "info" | "error", event: string, data: Record<string, unknown> = {}) {
  if (level === "debug" && !DEBUG) return
  if (!logStream) {
    mkdirSync(dirname(LOG_PATH), { recursive: true })
    logStream = createWriteStream(LOG_PATH, { flags: "a" })
  }
  logStream.write(`${JSON.stringify({ ...data, timestamp: new Date().toISOString(), level, event, pid: process.pid })}\n`)
}

function traeHome() {
  if (process.env.TRAECLI_HOME) return process.env.TRAECLI_HOME
  return join(process.env.TRAE_HOME ?? join(homedir(), ".trae"), "cli")
}

async function accessToken() {
  const auth = await Bun.file(join(traeHome(), "auth.json")).json()
  const token = auth.trae?.access_token
  if (typeof token !== "string" || !token) throw new Error("Trae is not logged in; run `traex login`")
  return token
}

function contentParts(content: ChatMessage["content"]) {
  if (typeof content === "string") return [{ type: "text", text: content }]
  if (!content) return []
  return content
}

function messages(input: ChatMessage[]) {
  return input.map((message) => ({
    role: message.role,
    content: contentParts(message.content),
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
  }))
}

function userInput(input: ChatMessage[]) {
  const content = input.findLast((message) => message.role === "user")?.content
  if (typeof content === "string") return content
  if (!Array.isArray(content)) return ""
  return content
    .filter((part) => part.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n")
}

function tools(input: Array<Record<string, unknown>>) {
  return input.map((tool) => {
    if (tool.type !== "function" || typeof tool.function !== "object" || !tool.function) return tool
    const { strict: _, parameters, ...definition } = tool.function as Record<string, unknown>
    return {
      ...tool,
      function: {
        ...definition,
        parameters: typeof parameters === "string" ? parameters : JSON.stringify(parameters ?? {}),
      },
    }
  })
}

async function refreshAuth() {
  const process = Bun.spawn(["traex", "models"], { stdout: "ignore", stderr: "ignore" })
  await process.exited
}

async function requestTrae(body: ChatRequest, signal: AbortSignal, state: RequestState, attempt = 1): Promise<Response> {
  const model = models[body.model]
  const id = crypto.randomUUID()
  const payload = {
    access_type: 4,
    config_name: model.config,
    conversation_id: id,
    extra_info: "",
    is_preset: true,
    max_tokens: body.max_tokens ?? body.max_completion_tokens ?? 32_768,
    messages: messages(body.messages),
    model_name: model.backend,
    parallel_tool_calls: body.parallel_tool_calls ?? true,
    session_id: id,
    tools: tools(body.tools ?? []),
    user_input: userInput(body.messages),
  }
  const encoded = JSON.stringify(payload)
  state.requestBytes = Buffer.byteLength(encoded)
  log("info", "request.start", {
    traceID: state.traceID,
    attempt,
    model: body.model,
    backendModel: model.backend,
    requestBytes: state.requestBytes,
    messageCount: payload.messages.length,
    toolCount: payload.tools.length,
  })
  log("debug", "request.shape", {
    traceID: state.traceID,
    messages: payload.messages.map((message) => ({
      role: message.role,
      content: message.content.map((part) => ({ type: part.type, bytes: Buffer.byteLength(JSON.stringify(part)) })),
      toolCalls: "tool_calls" in message ? message.tool_calls?.length : 0,
    })),
    tools: payload.tools.map((tool) => ({
      type: tool.type,
      name:
        typeof tool.function === "object" && tool.function && "name" in tool.function ? tool.function.name : undefined,
      bytes: Buffer.byteLength(JSON.stringify(tool)),
    })),
  })
  const fetchStarted = performance.now()
  const response = await fetch(
    TRAE_URL,
    {
      method: "POST",
      signal,
      headers: {
        accept: "text/event-stream",
        authorization: `Cloud-CLI-JWT ${await accessToken()}`,
        "content-type": "application/json",
        originator: "opencode",
        version: "1",
        "x-agent-flag": "1",
        "x-app-id": TRAE_APP_ID,
        "x-ide-function": "traecli_next",
        "x-ide-version-code": new Date().toISOString().slice(0, 10).replaceAll("-", ""),
      },
      body: encoded,
      verbose: DEBUG,
    } as RequestInit & { verbose: boolean },
  ).catch((error) => {
    state.elapsedMs = performance.now() - fetchStarted
    state.error = errorInfo(error)
    log("error", "request.fetch.error", { traceID: state.traceID, attempt, elapsedMs: state.elapsedMs, error: state.error })
    throw error
  })
  state.upstreamStatus = response.status
  log("info", "request.headers", {
    traceID: state.traceID,
    attempt,
    elapsedMs: performance.now() - fetchStarted,
    status: response.status,
    contentType: response.headers.get("content-type"),
    contentLength: response.headers.get("content-length"),
    requestID: response.headers.get("x-request-id") ?? response.headers.get("x-tt-logid"),
  })
  if (attempt === 1 && (response.status === 401 || response.status === 403)) {
    await response.body?.cancel()
    log("info", "request.auth.refresh", { traceID: state.traceID, status: response.status })
    await refreshAuth()
    return requestTrae(body, signal, state, attempt + 1)
  }
  if (!response.ok) {
    log("error", "request.rejected", { traceID: state.traceID, attempt, status: response.status })
  }
  return response
}

function chunk(model: string, delta: Record<string, unknown>, finishReason: string | null = null) {
  return JSON.stringify({
    id: `chatcmpl-${crypto.randomUUID()}`,
    object: "chat.completion.chunk",
    created: Math.floor(Date.now() / 1_000),
    model,
    choices: [{ index: 0, delta, finish_reason: finishReason }],
  })
}

function finishReason(reason: string | undefined) {
  if (reason === "tool_use" || reason === "function_call") return "tool_calls"
  if (reason === "max_tokens") return "length"
  return reason ?? "stop"
}

function translate(eventName: string, event: TraeEvent, model: string, state: RequestState) {
  state.eventCount++
  if (eventName === "output") state.outputEventCount++
  log("debug", "stream.event", {
    traceID: state.traceID,
    upstreamEvent: eventName,
    keys: Object.keys(event),
    responseBytes: typeof event.response === "string" ? Buffer.byteLength(event.response) : 0,
    reasoningBytes: typeof event.reasoning_content === "string" ? Buffer.byteLength(event.reasoning_content) : 0,
    toolCallCount: event.tool_calls?.length ?? 0,
  })
  if (eventName === "metadata" || eventName === "timing_cost") {
    const served = event.provider_model_name ?? event.model
    if (typeof served === "string") state.servedModel = served
  }
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
    return `data: ${JSON.stringify({
      choices: [],
      usage: {
        prompt_tokens: event.prompt_tokens,
        completion_tokens: event.completion_tokens,
        total_tokens: event.total_tokens,
        prompt_tokens_details: { cached_tokens: event.cache_read_input_tokens ?? 0 },
        completion_tokens_details: { reasoning_tokens: event.reasoning_tokens ?? 0 },
      },
    })}\n\n`
  }
  if (eventName === "done") {
    return `data: ${chunk(model, {}, finishReason(event.finish_reason))}\n\ndata: [DONE]\n\n`
  }
  if (eventName === "error") {
    const message = typeof event.message === "string" ? event.message : JSON.stringify(event)
    return `data: ${JSON.stringify({ error: { message } })}\n\n`
  }
  return ""
}

function translatedStream(response: Response, model: string, state: RequestState) {
  const reader = response.body!.getReader()
  const decoder = new TextDecoder()
  const encoder = new TextEncoder()
  let buffer = ""
  let sawDone = false
  let cancelled = false
  const elapsed = () => Date.now() - Date.parse(state.startedAt)
  const processBlock = (block: string, controller: ReadableStreamDefaultController<Uint8Array>) => {
    const eventName = block.match(/^event:\s*(.+)$/m)?.[1] ?? ""
    const data = block
      .split(/\r?\n/)
      .filter((line) => line.startsWith("data:"))
      .map((line) => line.slice(5).trimStart())
      .join("\n")
    if (!data) return
    if (eventName === "progress_notice") {
      state.progressNoticeCount++
      log("debug", "stream.progress", {
        traceID: state.traceID,
        upstreamEvent: eventName,
        bytes: Buffer.byteLength(block),
        dataPreview: data.slice(0, 100),
      })
      const encoded = encoder.encode(`: ${data}\n\n`)
      state.downstreamBytes += encoded.byteLength
      controller.enqueue(encoded)
      return
    }
    let event: TraeEvent
    try {
      event = JSON.parse(data)
    } catch (error) {
      log("error", "stream.parse.error", {
        traceID: state.traceID,
        upstreamEvent: eventName,
        blockBytes: Buffer.byteLength(block),
        dataPreview: data.slice(0, 500),
        error: errorInfo(error),
      })
      throw error
    }
    const output = translate(eventName, event, model, state)
    if (eventName === "done") sawDone = true
    if (!output) return
    const encoded = encoder.encode(output)
    state.downstreamBytes += encoded.byteLength
    controller.enqueue(encoded)
  }
  log("info", "stream.start", { traceID: state.traceID, status: response.status })
  return new ReadableStream<Uint8Array>({
    async start(controller) {
      try {
        while (true) {
          const value = await reader.read()
          if (value.done) break
          state.upstreamBytes += value.value.byteLength
          buffer += decoder.decode(value.value, { stream: true })
          const blocks = buffer.split(/\r?\n\r?\n/)
          buffer = blocks.pop() ?? ""
          for (const block of blocks) processBlock(block, controller)
        }
        if (cancelled) return
        buffer += decoder.decode()
        if (buffer.trim()) processBlock(buffer, controller)
        state.elapsedMs = elapsed()
        state.completed = true
        state.sawDone = sawDone
        log(sawDone ? "info" : "error", "stream.complete", {
          traceID: state.traceID,
          elapsedMs: state.elapsedMs,
          upstreamBytes: state.upstreamBytes,
          downstreamBytes: state.downstreamBytes,
          eventCount: state.eventCount,
          outputEventCount: state.outputEventCount,
          progressNoticeCount: state.progressNoticeCount,
          sawDone,
        })
        controller.close()
      } catch (error) {
        if (cancelled || (sawDone && error instanceof Error && error.name === "AbortError")) return
        state.elapsedMs = elapsed()
        state.completed = false
        state.sawDone = sawDone
        state.error = errorInfo(error)
        log("error", "stream.error", {
          traceID: state.traceID,
          elapsedMs: state.elapsedMs,
          upstreamBytes: state.upstreamBytes,
          downstreamBytes: state.downstreamBytes,
          eventCount: state.eventCount,
          outputEventCount: state.outputEventCount,
          progressNoticeCount: state.progressNoticeCount,
          sawDone,
          bufferedBytes: Buffer.byteLength(buffer),
          error: state.error,
        })
        controller.error(error)
      }
    },
    async cancel(reason) {
      cancelled = true
      state.elapsedMs = elapsed()
      state.completed = sawDone
      state.sawDone = sawDone
      log("info", sawDone ? "stream.complete" : "stream.cancel", {
        traceID: state.traceID,
        elapsedMs: state.elapsedMs,
        upstreamBytes: state.upstreamBytes,
        downstreamBytes: state.downstreamBytes,
        eventCount: state.eventCount,
        outputEventCount: state.outputEventCount,
        progressNoticeCount: state.progressNoticeCount,
        downstreamCancelled: true,
        ...(reason === undefined ? {} : { reason: errorInfo(reason) }),
      })
      await reader.cancel(reason).catch((error) =>
        log("debug", "stream.cancel.error", { traceID: state.traceID, error: errorInfo(error) }),
      )
    },
  })
}

async function handle(request: Request) {
  const url = new URL(request.url)
  if (request.method === "GET" && url.pathname === "/health") return new Response("ok")
  if (request.method === "GET" && url.pathname === "/debug/last") return Response.json(lastRequest ?? null)
  if (request.method !== "POST" || url.pathname !== "/v1/chat/completions") return new Response("Not found", { status: 404 })
  const traceID = crypto.randomUUID()
  try {
    const body = (await request.json()) as ChatRequest
    const model = models[body.model]
    if (!model) return Response.json({ error: { message: `Unknown Trae model: ${body.model}` } }, { status: 400 })
    const state: RequestState = {
      traceID,
      requestedModel: body.model,
      configName: model.config,
      backendModel: model.backend,
      upstreamURL: TRAE_URL,
      requestBytes: 0,
      upstreamBytes: 0,
      downstreamBytes: 0,
      eventCount: 0,
      progressNoticeCount: 0,
      outputEventCount: 0,
      startedAt: new Date().toISOString(),
    }
    lastRequest = state
    log("debug", "adapter.request", {
      traceID,
      method: request.method,
      path: url.pathname,
      contentLength: request.headers.get("content-length"),
      headerNames: [...request.headers.keys()].sort(),
    })
    const response = await requestTrae(body, request.signal, state)
    if (!response.ok || !response.body) {
      const responseBody = await response.text()
      state.elapsedMs = Date.now() - Date.parse(state.startedAt)
      state.completed = false
      log("error", "adapter.response.rejected", {
        traceID,
        status: response.status,
        elapsedMs: state.elapsedMs,
        responseBytes: Buffer.byteLength(responseBody),
        responseBody: DEBUG ? responseBody : undefined,
      })
      return Response.json(
        { error: { message: `Trae returned HTTP ${response.status}: ${responseBody}` } },
        { status: response.status },
      )
    }
    return new Response(translatedStream(response, body.model, state), {
      headers: { "cache-control": "no-cache", "content-type": "text/event-stream" },
    })
  } catch (error) {
    log("error", "adapter.error", { traceID, error: errorInfo(error) })
    return Response.json({ error: { message: error instanceof Error ? error.message : String(error) } }, { status: 502 })
  }
}

function startAdapter() {
  try {
    const server = Bun.serve({ hostname: HOST, port: PORT, idleTimeout: 255, fetch: handle })
    log("info", "adapter.listen", { host: HOST, port: PORT, debug: DEBUG })
    return server
  } catch (error) {
    if (!(error instanceof Error) || (!error.message.includes("EADDRINUSE") && !error.message.includes(`port ${PORT}`))) {
      log("error", "adapter.listen.error", { host: HOST, port: PORT, error: errorInfo(error) })
      throw error
    }
    log("info", "adapter.reuse", { host: HOST, port: PORT })
  }
}

export default {
  id: "trae.provider",
  async setup(context) {
    log("info", "plugin.setup", { directory: context.location.directory })
    const adapter = startAdapter()
    await context.provider.transform((providers) => {
      providers.update("trae", (provider) => {
        provider.name = "Trae"
        provider.activation = "enabled"
        provider.package = "aisdk:@ai-sdk/openai-compatible"
        provider.settings = { apiKey: "local", baseURL: `http://${HOST}:${PORT}/v1` }
      })
      for (const [id, info] of Object.entries(models)) {
        providers.models.update("trae", id, (model) => {
          model.name = id
          model.compatibility = {
            maxTokensField: "max_tokens",
            reasoningField: "reasoning_content",
            requireFinishReason: true,
          }
          model.capabilities = { tools: true, input: ["text"], output: ["text"] }
          model.limit = { context: info.context, output: 32_768 }
        })
      }
    })
    return () => {
      log("info", "plugin.cleanup", { directory: context.location.directory, ownsAdapter: Boolean(adapter) })
      adapter?.stop()
    }
  },
}
