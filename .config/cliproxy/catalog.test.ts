import { expect, test } from "bun:test"
import { normalizeCatalog, preferTraeMax } from "./catalog"
import { applyCatalog } from "../opencode/plugins/trae/provider"

test("prefers Trae Max only when available and leaves other provider pairs visible", () => {
  const entries = ["Trae", "Trae-Max", "Single", "Other", "Other-Max"].map((id) => ({ slug: id }))
  const models = normalizeCatalog(entries, new Map([["Trae", "trae"], ["Trae-Max", "trae"], ["Single", "trae"]]), new Map())
  expect(models.map((model) => model.id)).toEqual(["Trae-Max", "Single", "Other", "Other-Max"])
  expect(preferTraeMax([{ id: "Trae" }, { id: "Trae-Max" }, { id: "Single" }], new Set(["Trae", "Single"]))).toEqual([{ id: "Trae-Max" }, { id: "Single" }])
})

test("filters media and hidden routes and supplements Trae output limits", () => {
  const models = normalizeCatalog([
    { slug: "Trae-Max", context_window: 800000, supported_reasoning_levels: [{ effort: "high" }], input_modalities: ["text", "image"] },
    { slug: "Fixed", display_name: "Fixed effort", max_tokens: 8192 },
    { slug: "hidden", visibility: "hide" },
    { slug: "disabled", supported_in_api: false },
    { slug: "grok-imagine-video", visibility: "list" },
    { slug: "gemini-3.1-flash-image", visibility: "list" },
  ], new Map([["Trae-Max", "trae"]]), new Map([["Trae-Max", 64000]]))
  expect(models).toEqual([
    { id: "Trae-Max", name: "Trae-Max", owner: "trae", context: 800000, output: 64000, reasoning: ["high"], input: ["text", "image"] },
    { id: "Fixed", name: "Fixed effort", owner: "", output: 8192, reasoning: [], input: ["text"] },
  ])
})

test("OpenCode replaces inventories, preserves Trae identity, and routes both providers through CLIProxyAPI", () => {
  const records = new Map<string, { provider: any; models: Map<string, any> }>()
  const editor = {
    update(id: string, update: (provider: any) => void) {
      if (!records.has(id)) records.set(id, { provider: {}, models: new Map() })
      update(records.get(id)!.provider)
    },
    models: {
      set(id: string) { records.get(id)!.models.clear() },
      update(provider: string, id: string, update: (model: any) => void) {
        const model = { limit: {} }
        update(model)
        records.get(provider)!.models.set(id, model)
      },
    },
  }
  const models = normalizeCatalog([{ slug: "Trae", context_window: 475000, supported_reasoning_levels: [{ effort: "low" }] }, { slug: "Other" }], new Map([["Trae", "trae"]]), new Map([["Trae", 32000]]))
  applyCatalog(editor, models)
  expect([...records.get("trae")!.models.keys()]).toEqual(["Trae"])
  expect([...records.get("cliproxy")!.models.keys()]).toEqual(["Other"])
  expect(records.get("trae")!.provider.settings).toMatchObject({ baseURL: "http://127.0.0.1:8317/v1", apiKey: "api-key" })
  expect(records.get("trae")!.models.get("Trae")).toMatchObject({ limit: { context: 475000, output: 32000 }, variants: [{ id: "low", settings: { reasoningEffort: "low" } }] })
  applyCatalog(editor, models.slice(1))
  expect(records.get("trae")!.models.size).toBe(0)
})
