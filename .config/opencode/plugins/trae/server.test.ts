import { describe, expect, test } from "bun:test"
import type { ModelRoute } from "./provider"
import { createTraeHandler, renderCliProxyBlock, updateCliProxyConfigText } from "./server"

const sampleModels: Readonly<Record<string, ModelRoute>> = {
  "GPT-5.4": {
    name: "GPT-5.4",
    config: "gpt-5.4",
    backend: "gpt-5.4__dev",
    context: 272_000,
    output: 32_768,
    reasoning: ["low", "medium", "high", "xhigh"],
    input: ["text", "image"],
  },
  "GPT-6.1-Sol-Max": {
    name: "GPT-6.1-Sol / Max",
    config: "gpt-6.1-sol",
    backend: "gpt-6.1-sol__max",
    context: 1_000_000,
    output: 64_000,
    reasoning: ["low", "medium", "high", "xhigh"],
    input: ["text", "image"],
  },
  "Seed-Code": {
    name: "Seed-Code",
    config: "seed-code",
    backend: "seed-code__dev",
    context: 128_000,
    output: 16_384,
    reasoning: [],
    input: ["text"],
  },
}

describe("CLIProxyAPI config sync", () => {
  test("renders openai-compatibility block with thinking levels, modalities, and context length", () => {
    const block = renderCliProxyBlock(sampleModels, "http://127.0.0.1:43821/v1")
    expect(block).toContain('name: "trae"')
    expect(block).toContain('base-url: "http://127.0.0.1:43821/v1"')
    expect(block).toContain("disable-cooling: true")
    expect(block).toContain('api-key: "loopback-no-auth"')
    expect(block).toContain('name: "GPT-5.4"')
    expect(block).toContain("max-context-length: 272000")
    expect(block).toContain('input-modalities: ["text", "image"]')
    expect(block).toContain('levels: ["low", "medium", "high", "xhigh"]')
    expect(block).toContain('display-name: "GPT-6.1-Sol / Max"')
    expect(block).toContain('name: "Seed-Code"')
    expect(block).toContain("levels: []")
  })

  test("inserts and updates the managed block idempotently", () => {
    const initial = "config-version: 8\nserver:\n  port: 8317\n"
    const updated1 = updateCliProxyConfigText(initial, sampleModels, "http://127.0.0.1:43821/v1")
    expect(updated1).toContain("# BEGIN TRAE OPENAI-COMPATIBILITY")
    expect(updated1).toContain("# END TRAE OPENAI-COMPATIBILITY")

    const updated2 = updateCliProxyConfigText(updated1, sampleModels, "http://127.0.0.1:43821/v1")
    expect(updated2).toBe(updated1)
  })
})

describe("Trae OpenAI-compatible HTTP handler", () => {
  test("serves /v1/models, non-streaming and streaming /v1/chat/completions, and refreshes auth on 401", async () => {
    let attempts = 0
    let refreshed = 0

    const upstream = Bun.serve({
      port: 0,
      async fetch(req) {
        attempts += 1
        if (attempts === 1) {
          return new Response("expired", { status: 401 })
        }
        const body = (await req.json()) as Record<string, unknown>
        const sse = [
          `event: progress_notice\ndata: ;Processing_123\n\n`,
          `event: output\ndata: ${JSON.stringify({ reasoning_content: `think(${body.reasoning_effort ?? "none"})` })}\n\n`,
          `event: output\ndata: ${JSON.stringify({ response: `PONG:${body.model_name}` })}\n\n`,
          `event: token_usage\ndata: ${JSON.stringify({ prompt_tokens: 10, completion_tokens: 5, total_tokens: 15, reasoning_tokens: 2 })}\n\n`,
          `event: done\ndata: ${JSON.stringify({ finish_reason: "stop" })}\n\n`,
        ].join("")
        return new Response(sse, { headers: { "content-type": "text/event-stream" } })
      },
    })

    try {
      const handler = createTraeHandler({
        getModels: () => sampleModels,
        buildUpstreamRequest: async (req) => {
          const body = (await req.json()) as { model: string; reasoning_effort?: string }
          const route = sampleModels[body.model]
          return new Request(`http://127.0.0.1:${upstream.port}/api/ide/v2/llm_raw_chat`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ model_name: route.backend, reasoning_effort: body.reasoning_effort }),
          })
        },
        onRefreshAuth: async () => {
          refreshed += 1
        },
      })

      // 1. GET /v1/models
      const modelsResp = await handler(new Request("http://127.0.0.1/v1/models"))
      const modelsJson = (await modelsResp.json()) as { data: Array<{ id: string; owned_by: string }> }
      expect(modelsJson.data.map((m) => m.id)).toEqual(["GPT-5.4", "GPT-6.1-Sol-Max", "Seed-Code"])

      // 2. Non-streaming POST /v1/chat/completions (triggers 401 -> refresh -> 200)
      const nonStreamResp = await handler(
        new Request("http://127.0.0.1/v1/chat/completions", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            model: "GPT-5.4",
            reasoning_effort: "xhigh",
            messages: [{ role: "user", content: "hi" }],
            stream: false,
          }),
        }),
      )
      expect(nonStreamResp.status).toBe(200)
      expect(refreshed).toBe(1)
      const nonStreamJson = (await nonStreamResp.json()) as Record<string, any>
      expect(nonStreamJson.object).toBe("chat.completion")
      expect(nonStreamJson.model).toBe("GPT-5.4")
      expect(nonStreamJson.choices[0].message).toEqual({
        role: "assistant",
        content: "PONG:gpt-5.4__dev",
        reasoning_content: "think(xhigh)",
      })
      expect(nonStreamJson.choices[0].finish_reason).toBe("stop")
      expect(nonStreamJson.usage.total_tokens).toBe(15)

      // 3. Streaming POST /v1/chat/completions
      const streamResp = await handler(
        new Request("http://127.0.0.1/v1/chat/completions", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            model: "GPT-6.1-Sol-Max",
            messages: [{ role: "user", content: "hi" }],
            stream: true,
          }),
        }),
      )
      expect(streamResp.status).toBe(200)
      const streamText = await streamResp.text()
      expect(streamText).toContain("PONG:gpt-6.1-sol__max")
      expect(streamText).toContain("data: [DONE]")

      // 4. Omitted stream defaults to non-streaming chat.completion JSON
      const omittedStreamResp = await handler(
        new Request("http://127.0.0.1/v1/chat/completions", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            model: "GPT-5.4",
            messages: [{ role: "user", content: "hi" }],
          }),
        }),
      )
      expect(omittedStreamResp.status).toBe(200)
      const omittedStreamJson = (await omittedStreamResp.json()) as Record<string, any>
      expect(omittedStreamJson.object).toBe("chat.completion")
      expect(omittedStreamJson.choices[0].message.content).toBe("PONG:gpt-5.4__dev")
    } finally {
      upstream.stop(true)
    }
  })
})
