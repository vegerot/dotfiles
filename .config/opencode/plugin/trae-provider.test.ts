import { afterAll, beforeAll, describe, expect, test } from "bun:test"
import type { ModelRoute } from "./trae-provider"

const logPath = `${Bun.env.TMPDIR ?? "/tmp"}/trae-provider-test-${process.pid}.log`
Bun.env.OPENCODE_TRAE_LOG = logPath

type Provider = typeof import("./trae-provider")
let provider: Provider

beforeAll(async () => {
  provider = await import("./trae-provider")
})

afterAll(async () => {
  await Bun.file(logPath).delete().catch(() => {})
})

describe("OpenAI Chat request to Trae raw chat", () => {
  test("preserves conversation history and converts tool schemas", () => {
    const route: ModelRoute = {
      name: "GPT-5.6-Sol",
      sourceSlug: "GPT-5.6-Sol",
      mode: "standard",
      config: "gpt-5.6-sol",
      backend: "gpt-5.6-sol__dev",
      context: 272_000,
      output: 32_768,
    }
    const payload = provider.buildTraePayload(
      {
        model: "GPT-5.6-Sol",
        max_tokens: 4_096,
        parallel_tool_calls: false,
        messages: [
          { role: "system", content: "Be concise" },
          {
            role: "assistant",
            content: null,
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
    const state = {
      traceID: "trace-1",
      requestedModel: "GPT-5.6-Sol",
      sourceSlug: "GPT-5.6-Sol",
      mode: "standard",
      configName: "gpt-5.6-sol",
      backendModel: "gpt-5.6-sol__dev",
      contextWindow: 272_000,
      upstreamURL: "https://example.test",
      requestBytes: 0,
      upstreamBytes: 0,
      downstreamBytes: 0,
      eventCount: 0,
      progressNoticeCount: 0,
      outputEventCount: 0,
      startedAt: new Date().toISOString(),
    }

    const response = new Response(provider.translatedStream(new Response(upstream), "GPT-5.6-Sol", state))
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
    expect(state).toMatchObject({
      completed: true,
      sawDone: true,
      eventCount: 4,
      outputEventCount: 1,
      progressNoticeCount: 1,
    })
  })
})
