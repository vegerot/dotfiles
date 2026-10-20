import { type ModelRoute, cachePath, refreshCache } from "./protocol"

type LoadCatalog = {
  fetched_at: string
  models: {
    slug: string
    business_metadata?: {
      load?: { load_percent?: number; queue_size?: number | null } | null
      internal_usage?: { usage_percent: number; quota_remaining: number; quota_limit: number; reset_time: number } | null
    }
  }[]
}

export function modelLoads(snapshot: LoadCatalog, routes: Readonly<Record<string, ModelRoute>>) {
  const visible = Object.entries(routes).filter(([id]) => !routes[`${id}-Max`])
  const metadata = new Map(snapshot.models.map((model) => [model.slug, model.business_metadata]))
  const quota = snapshot.models.find((model) => model.business_metadata?.internal_usage)?.business_metadata?.internal_usage
  return {
    observedAt: snapshot.fetched_at,
    models: visible.map(([id, route]) => {
      const load = metadata.get(id.endsWith("-Max") ? id.slice(0, -4) : id)?.load
      return {
        id,
        name: route.name,
        loadPercent: load?.load_percent ?? null,
        queueSize: load?.queue_size ?? null,
      }
    }),
    weeklyQuota: quota ? { usedPercent: quota.usage_percent, remaining: quota.quota_remaining, limit: quota.quota_limit, resetAt: quota.reset_time } : null,
  }
}

let refreshing: Promise<void> | undefined
let refreshedAt = 0
export async function readModelLoads(routes: Readonly<Record<string, ModelRoute>>, refresh: boolean) {
  if (refresh && Date.now() - refreshedAt >= 30_000) {
    refreshing ??= refreshCache().then(() => { refreshedAt = Date.now() }).finally(() => { refreshing = undefined })
    await refreshing
  }
  return modelLoads(await Bun.file(cachePath()).json(), routes)
}
