// Shared by the Pi and OpenCode adapters. No host SDK or Trae credentials here.
export const PROXY_URL = process.env.CLIPROXY_URL ?? "http://127.0.0.1:8317/v1"
export const PROXY_KEY = process.env.CLIPROXY_API_KEY ?? "api-key"
const TRAE_URL = process.env.TRAE_OPENAI_URL ?? "http://127.0.0.1:43821/v1"
const MEDIA_MODEL_PATTERN = /gpt-image|imagine|(^|[-/])(image|video|tts)/i

export type CatalogModel = {
  id: string
  name: string
  owner: string
  input: string[]
  reasoning: string[]
  context?: number
  output?: number
}

// Prefer Max in model pickers while keeping Standard callable at the proxy.
export function preferTraeMax<T extends { id: string }>(models: T[], traeIDs: ReadonlySet<string>): T[] {
  const ids = new Set(models.map((model) => model.id))
  return models.filter((model) => !traeIDs.has(model.id) || !ids.has(`${model.id}-Max`))
}

type RemoteModel = {
  slug?: string
  id?: string
  display_name?: string
  visibility?: string
  supported_in_api?: boolean
  input_modalities?: string[]
  supported_reasoning_levels?: { effort: string }[]
  context_window?: number
  max_tokens?: number
}

export function normalizeCatalog(
  entries: RemoteModel[],
  owners: ReadonlyMap<string, string>,
  outputCaps: ReadonlyMap<string, number>,
): CatalogModel[] {
  const models = entries.flatMap((entry) => {
    const id = entry.slug ?? entry.id
    if (!id || MEDIA_MODEL_PATTERN.test(id) || entry.supported_in_api === false) return []
    if (entry.visibility && entry.visibility !== "list") return []
    const output = outputCaps.get(id) ?? entry.max_tokens
    return [{
      id,
      name: entry.display_name || id,
      owner: owners.get(id) ?? "",
      input: entry.input_modalities?.filter((x) => x === "text" || x === "image") ?? ["text"],
      reasoning: entry.supported_reasoning_levels?.map((x) => x.effort) ?? [],
      ...(entry.context_window ? { context: entry.context_window } : {}),
      ...(output ? { output } : {}),
    }]
  })
  return preferTraeMax(models, new Set(models.filter((model) => model.owner === "trae").map((model) => model.id)))
}

export async function fetchCatalog(signal: AbortSignal): Promise<CatalogModel[]> {
  const request = (url: string, auth = false) => fetch(url, {
    signal: AbortSignal.any([signal, AbortSignal.timeout(3000)]),
    ...(auth ? { headers: { authorization: `Bearer ${PROXY_KEY}` } } : {}),
  })
  const [rich, ordinary, trae] = await Promise.all([
    // Any nonempty client_version selects CLIProxyAPI's rich Codex catalog.
    request(`${PROXY_URL}/models?client_version=0.1.250313`, true),
    request(`${PROXY_URL}/models`, true),
    // Optional: Trae's output caps are missing from CLIProxyAPI's rich response.
    request(`${TRAE_URL}/models`).catch(() => null),
  ])
  if (!rich.ok || !ordinary.ok) throw new Error(`CLIProxyAPI catalog HTTP ${!rich.ok ? rich.status : ordinary.status}`)
  const [catalog, sources] = await Promise.all([
    rich.json() as Promise<{ models: RemoteModel[] }>,
    ordinary.json() as Promise<{ data: { id: string; owned_by: string }[] }>,
  ])
  const outputCaps = new Map<string, number>()
  if (trae?.ok) {
    const supplemental = await trae.json() as { data: { id: string; max_completion_tokens: number }[] }
    for (const model of supplemental.data) outputCaps.set(model.id, model.max_completion_tokens)
  }
  return normalizeCatalog(catalog.models, new Map(sources.data.map((x) => [x.id, x.owned_by])), outputCaps)
}
