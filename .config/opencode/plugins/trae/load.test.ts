import { expect, test } from "bun:test"
import { modelLoads } from "./load"

test("shares model-level load with Max, preserves overload and unknown data, and deduplicates routes", () => {
  const route = { name: "Model", config: "model", backend: "model", context: 1000, output: 100, reasoning: [], input: ["text"] as const }
  const result = modelLoads({ fetched_at: "2026-10-20T22:00:00Z", models: [
    { slug: "Model", business_metadata: { load: { load_percent: 117, queue_size: 3 } } },
    { slug: "Quota", business_metadata: { internal_usage: { usage_percent: 10, quota_remaining: 270, quota_limit: 300, reset_time: 123 } } },
  ] }, { Model: route, "Model-Max": route, Unknown: route })
  expect(result.models).toEqual([
    { id: "Model-Max", name: "Model", loadPercent: 117, queueSize: 3 },
    { id: "Unknown", name: "Model", loadPercent: null, queueSize: null },
  ])
  expect(result.observedAt).toBe("2026-10-20T22:00:00Z")
  expect(result.weeklyQuota?.remaining).toBe(270)
})
