type WeeklyQuota = Readonly<{
  applies?: boolean
  remainingPercent?: number
  resetTime?: number
}>

type TraeModel = Readonly<{
  name?: string
  _meta?: Readonly<{
    trae?: Readonly<{
      load?: Readonly<{ percent?: number }>
      weeklyQuota?: WeeklyQuota
    }>
  }>
}>

export type TraeStatus = Readonly<{
  models: ReadonlyArray<
    Readonly<{
      name: string
      loadPercent?: number
      weeklyQuotaApplies?: boolean
    }>
  >
  weeklyQuota?: Readonly<{
    remainingPercent: number
    resetTime?: number
  }>
}>

export function isTraeModel(model: Readonly<{ providerID: string }> | undefined) {
  return model?.providerID === "trae"
}

export async function readTraeStatus(
  run: (args: readonly string[]) => Promise<string>,
  refresh: boolean,
) {
  if (refresh) await run(["debug", "models", "--remote"])
  return parseTraeStatus(JSON.parse(await run(["models", "--json"])))
}

export function footerStatus(
  model: Readonly<{ providerID: string; modelID: string }> | undefined,
  status: TraeStatus | undefined,
) {
  if (!isTraeModel(model) || !status) return
  const name = model.modelID.endsWith("-Max") ? model.modelID.slice(0, -4) : model.modelID
  const current = status.models.find((item) => item.name === name)
  if (current?.weeklyQuotaApplies && status.weeklyQuota)
    return `Trae weekly ${status.weeklyQuota.remainingPercent}% left`
  if (current?.loadPercent !== undefined) return `Trae load ${current.loadPercent}%`
}

export function formatTraeStatus(status: TraeStatus, timeZone?: string) {
  const quota = status.weeklyQuota
  const lines = quota
    ? [
        `Weekly: ${quota.remainingPercent}% left${quota.resetTime === undefined ? "" : `, resets ${new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", hour: "numeric", minute: "2-digit", timeZone }).format(quota.resetTime * 1_000)}`}`,
        "",
      ]
    : []
  const loads = status.models.filter((model) => model.loadPercent !== undefined)
  if (loads.length) {
    lines.push("Model load:")
    lines.push(...loads.map((model) => `${model.name}  ${model.loadPercent}%`))
  }
  return lines.join("\n") || "Trae status is unavailable."
}

export function parseTraeStatus(input: unknown): TraeStatus {
  if (!Array.isArray(input)) throw new Error("Invalid `traex models --json` output")

  let weeklyQuota: TraeStatus["weeklyQuota"]
  const models = input.flatMap((value) => {
    if (typeof value !== "object" || !value) return []
    const model = value as TraeModel
    if (typeof model.name !== "string") return []
    const metadata = model._meta?.trae
    const quota = metadata?.weeklyQuota
    if (!weeklyQuota && quota?.applies) {
      weeklyQuota = {
        remainingPercent: quota.remainingPercent ?? 100,
        ...(typeof quota.resetTime === "number" ? { resetTime: quota.resetTime } : {}),
      }
    }
    return [
      {
        name: model.name,
        ...(typeof metadata?.load?.percent === "number" ? { loadPercent: metadata.load.percent } : {}),
        ...(quota?.applies ? { weeklyQuotaApplies: true } : {}),
      },
    ]
  })

  return { models, ...(weeklyQuota ? { weeklyQuota } : {}) }
}
