import type { Context } from "@opencode/plugin/promise/plugin"
import type { ProviderEditor } from "@opencode/plugin/promise/provider"
import { type CatalogModel, fetchCatalog, PROXY_URL, PROXY_KEY } from "../../../cliproxy/catalog"

export function applyCatalog(providers: ProviderEditor, models: readonly CatalogModel[]) {
  for (const providerID of ["trae", "cliproxy"]) {
    providers.update(providerID, (provider) => {
      provider.name = providerID === "trae" ? "Trae" : "CLIProxyAPI"
      provider.activation = "enabled"
      provider.package = "@opencode/ai/providers/openai-compatible"
      provider.settings = { baseURL: PROXY_URL, apiKey: PROXY_KEY, provider: providerID }
    })
    // Replace the inventory so deleted routes disappear on refresh.
    providers.models.set(providerID, [])
    for (const info of models) {
      if ((info.owner === "trae" ? "trae" : "cliproxy") !== providerID) continue
      providers.models.update(providerID, info.id, (model) => {
        model.name = info.name
        model.compatibility = {
          maxTokensField: "max_tokens",
          reasoningField: "reasoning_content",
          requireFinishReason: true,
        }
        model.capabilities = { tools: true, input: [...info.input], output: ["text"] }
        if (info.context) model.limit.context = info.context
        if (info.output) model.limit.output = info.output
        model.variants = info.reasoning.map((effort) => ({ id: effort, settings: { reasoningEffort: effort } }))
      })
    }
  }
}

export default {
  id: "trae.provider",
  async setup(context: Context) {
    let models: CatalogModel[] = (await context.storage.get("catalog") as CatalogModel[] | undefined) ?? []
    let registered = false
    const controller = new AbortController()
    const refresh = async () => {
      try {
        const next = await fetchCatalog(controller.signal)
        if (controller.signal.aborted || !next.length || JSON.stringify(next) === JSON.stringify(models)) return
        models = next
        await context.storage.set("catalog", models)
        if (registered) await context.provider.reload()
      } catch (error) {
        if (!controller.signal.aborted) console.error("CLIProxyAPI model refresh failed; keeping cached catalog", error)
      }
    }
    // Await initial local discovery so a fresh headless run has models.
    await refresh()
    await context.provider.transform((providers) => applyCatalog(providers, models))
    registered = true
    const timer = setInterval(refresh, 30_000)
    timer.unref()
    return () => {
      clearInterval(timer)
      controller.abort()
    }
  },
}
