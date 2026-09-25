import { beforeAll, describe, expect, test } from "bun:test"
import type { ModelRoute } from "./trae-provider"

type Provider = typeof import("./trae-provider")
let provider: Provider

beforeAll(async () => {
  provider = await import("./trae-provider")
})

describe("Trae model catalog", () => {
  test("registers visible standard and Max routes from explicit cache metadata", () => {
    const snapshot = provider.translateCatalog(
      {
        models: [
          {
            slug: "Visible",
            config_name: "visible",
            visibility: "list",
            supported_reasoning_levels: [{ effort: "low" }, { effort: "high" }],
            business_metadata: {
              variants: {
                standard_key: "visible__dev",
                standard_context_window: 100_000,
                max_key: "visible__max",
                max_context_window: 800_000,
                backend_token_limits: {
                  visible__dev: { output_tokens: 8_192 },
                  visible__max: { output_tokens: 64_000 },
                },
              },
            },
          },
          {
            slug: "Hidden",
            config_name: "hidden",
            visibility: "hidden",
            business_metadata: {
              variants: { standard_key: "hidden__dev", standard_context_window: 100_000 },
            },
          },
          {
            slug: "Disabled",
            config_name: "disabled",
            visibility: "list",
            supported_in_api: false,
            business_metadata: {
              variants: { standard_key: "disabled__dev", standard_context_window: 100_000 },
            },
          },
        ],
      },
      "/catalog.json",
    )

    expect(snapshot.models).toEqual({
      Visible: {
        name: "Visible",
        config: "visible",
        backend: "visible__dev",
        context: 100_000,
        output: 8_192,
        reasoning: ["low", "high"],
      },
      "Visible-Max": {
        name: "Visible / Max",
        config: "visible",
        backend: "visible__max",
        context: 800_000,
        output: 64_000,
        reasoning: ["low", "high"],
      },
    })
  })

  test("exposes Trae reasoning efforts as OpenCode variants", () => {
    expect(provider.reasoningVariants(["low", "high"])).toEqual([
      { id: "low", settings: { reasoningEffort: "low" } },
      { id: "high", settings: { reasoningEffort: "high" } },
    ])
  })

  test("rejects a visible model without an explicit standard route", () => {
    expect(() =>
      provider.translateCatalog(
        { models: [{ slug: "Incomplete", config_name: "incomplete", visibility: "list" }] },
        "/catalog.json",
      ),
    ).toThrow("Trae cache model Incomplete is missing its standard route")
  })
})

describe("OpenAI Chat request to Trae raw chat", () => {
  test("preserves conversation history and converts tool schemas", () => {
    const route: ModelRoute = {
      name: "GPT-5.6-Sol",
      config: "gpt-5.6-sol",
      backend: "gpt-5.6-sol__dev",
      context: 272_000,
      output: 32_768,
      reasoning: ["low", "medium", "high", "xhigh"],
    }
    const payload = provider.buildTraePayload(
      {
        model: "GPT-5.6-Sol",
        max_tokens: 4_096,
        parallel_tool_calls: false,
        reasoning_effort: "high",
        messages: [
          { role: "system", content: "Be concise" },
          {
            role: "assistant",
            content: null,
            reasoning_content: "I should read the file.",
            tool_calls: [{ id: "call-1", type: "function", function: { name: "read", arguments: "{\"path\":\"a\"}" } }],
          },
          { role: "tool", tool_call_id: "call-1", content: "contents" },
          { role: "user", content: [{ type: "text", text: "First" }, { type: "text", text: "Second" }] },
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "read",
              description: "Read a file",
              strict: true,
              parameters: { type: "object", properties: { path: { type: "string" } }, required: ["path"] },
            },
          },
        ],
      },
      route,
      "conversation-1",
    )

    expect(payload).toEqual({
      access_type: 4,
      config_name: "gpt-5.6-sol",
      conversation_id: "conversation-1",
      extra_info: "",
      is_preset: true,
      max_tokens: 4_096,
      messages: [
        { role: "system", content: [{ type: "text", text: "Be concise" }] },
        {
          role: "assistant",
          content: [],
          reasoning_content: "I should read the file.",
          tool_calls: [
            {
              id: "call-1",
              index: 0,
              type: "function",
              function_call: { name: "read", arguments: "{\"path\":\"a\"}" },
            },
          ],
        },
        { role: "tool", content: [{ type: "text", text: "contents" }], tool_call_id: "call-1" },
        { role: "user", content: [{ type: "text", text: "First" }, { type: "text", text: "Second" }] },
      ],
      model_name: "gpt-5.6-sol__dev",
      parallel_tool_calls: false,
      reasoning_effort: "high",
      session_id: "conversation-1",
      tools: [
        {
          type: "function",
          function: {
            name: "read",
            description: "Read a file",
            parameters: JSON.stringify({
              type: "object",
              properties: { path: { type: "string" } },
              required: ["path"],
            }),
          },
        },
      ],
      user_input: "First\nSecond",
    })
  })

  test("uses the selected route output limit by default", () => {
    const route: ModelRoute = {
      name: "Small model",
      config: "small-model",
      backend: "small-model__dev",
      context: 100_000,
      output: 8_192,
      reasoning: [],
    }

    const payload = provider.buildTraePayload(
      { model: "Small model", messages: [{ role: "user", content: "hello" }] },
      route,
      "conversation-1",
    )

    expect(payload.max_tokens).toBe(8_192)
  })
})

describe("Trae raw-chat stream to OpenAI Chat SSE", () => {
  test("translates reasoning, text, tools, usage, progress, and finish reason", async () => {
    const upstream = [
      'event: metadata\ndata: {"model":"gpt-5.6-sol"}',
      "event: progress_notice\ndata: ;Processing_123",
      'event: output\ndata: {"reasoning_content":"think","response":"answer","tool_calls":[{"id":"call-1","index":0,"function_call":{"name":"read","arguments":"{}"}}]}',
      'event: token_usage\ndata: {"prompt_tokens":10,"completion_tokens":4,"total_tokens":14,"cache_read_input_tokens":3,"reasoning_tokens":1}',
      'event: done\ndata: {"finish_reason":"tool_use"}',
    ].join("\n\n") + "\n\n"
    const response = new Response(provider.translatedStream(new Response(upstream), "GPT-5.6-Sol"))
    const output = await response.text()
    const frames = output
      .split("\n\n")
      .filter((frame) => frame.startsWith("data: ") && frame !== "data: [DONE]")
      .map((frame) => JSON.parse(frame.slice(6)))

    expect(output).toContain(": ;Processing_123\n\n")
    expect(frames[0].choices[0].delta).toEqual({
      content: "answer",
      reasoning_content: "think",
      tool_calls: [
        { index: 0, id: "call-1", type: "function", function: { name: "read", arguments: "{}" } },
      ],
    })
    expect(frames[1].usage).toEqual({
      prompt_tokens: 10,
      completion_tokens: 4,
      total_tokens: 14,
      prompt_tokens_details: { cached_tokens: 3 },
      completion_tokens_details: { reasoning_tokens: 1 },
    })
    expect(frames[2].choices[0].finish_reason).toBe("tool_calls")
    expect(output).toEndWith("data: [DONE]\n\n")
  })

  test("handles arbitrary byte boundaries and CRLF framing", async () => {
    const input = new TextEncoder().encode(
      [
        "event: progress_notice\r\ndata: ;Processing_123",
        'event: output\r\ndata: {"response":"héllo 🌍"}',
        'event: done\r\ndata: {"finish_reason":"stop"}',
      ].join("\r\n\r\n") + "\r\n\r\n",
    )
    const stream = new ReadableStream<Uint8Array>({
      start(controller) {
        for (const byte of input) controller.enqueue(Uint8Array.of(byte))
        controller.close()
      },
    })
    const output = await new Response(provider.translatedStream(new Response(stream), "GPT-5.6-Sol")).text()

    expect(output).toContain(": ;Processing_123\n\n")
    expect(output).toContain('"content":"héllo 🌍"')
    expect(output).toEndWith("data: [DONE]\n\n")
  })
})

describe("OpenCode retry policy", () => {
  test("refreshes authentication only after the first unauthorized attempt", () => {
    expect(provider.shouldRefreshAuth(1, 401)).toBeTrue()
    expect(provider.shouldRefreshAuth(1, 403)).toBeTrue()
    expect(provider.shouldRefreshAuth(2, 401)).toBeFalse()
    expect(provider.shouldRefreshAuth(1, 500)).toBeFalse()
  })
})
