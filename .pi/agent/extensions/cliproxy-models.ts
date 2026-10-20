// cliproxy-models — dynamic CLIProxyAPI model catalog for Pi.
//
// Pi's models.json model lists are static. CLIProxyAPI's OpenAI /v1/models only
// returns id/owned_by, but its Codex-client endpoint (?client_version=) returns
// full metadata (context window, output cap, reasoning levels, visibility), and
// the Trae loopback on :43821 adds output-token caps for Trae models. We
// register the "cliproxy" provider with a refreshModels hook; Pi persists the
// result to models-store.json and restores it before network refresh, so
// headless runs keep working when the proxies are down.
//
// The endpoints are localhost and cheap, so we also fetch them during Pi's
// cache-only refresh phase when no snapshot is stored yet. That lets headless
// `pi -p` populate the cache on first run instead of showing zero models.

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const PROXY_URL = process.env.CLIPROXY_URL ?? "http://127.0.0.1:8317/v1";
const PROXY_KEY = process.env.CLIPROXY_API_KEY ?? "api-key";
const TRAE_URL = process.env.TRAE_OPENAI_URL ?? "http://127.0.0.1:43821/v1";
// Any non-empty value selects the Codex catalog response; CLIProxyAPI does not gate on it.
const CLIENT_VERSION = "0.1.250313";
const FETCH_TIMEOUT_MS = 3000;

// Pi thinking levels in picker order. Catalog efforts not in this list (e.g. "ultra") are dropped.
const PI_THINKING_LEVELS = ["minimal", "low", "medium", "high", "xhigh", "max"] as const;

// CLIProxyAPI gives media models no model-type marker in this endpoint: image/video/tts
// entries ship alongside chat entries with visibility "list". Match by name instead.
const MEDIA_MODEL_PATTERN = /gpt-image|imagine|(^|[-/])(image|video|tts)/i;

type PiModel = {
  id: string;
  name: string;
  reasoning: boolean;
  input: string[];
  contextWindow?: number;
  maxTokens?: number;
  thinkingLevelMap?: Record<string, string | null>;
  // Extension models skip the models.json defaults, so cost is required (Pi reads model.cost.tiers).
  cost: { input: 0; output: 0; cacheRead: 0; cacheWrite: 0 };
};

const ZERO_COST = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } as const;

function sanitize(entries: unknown): PiModel[] {
  if (!Array.isArray(entries)) return [];
  const models: PiModel[] = [];
  for (const entry of entries) {
    if (!entry || typeof entry !== "object") continue;
    const record = entry as Record<string, unknown>;
    if (typeof record.id !== "string" || typeof record.name !== "string") continue;
    const model: PiModel = {
      id: record.id,
      name: record.name,
      reasoning: record.reasoning === true,
      input: Array.isArray(record.input) ? record.input.filter((x): x is string => x === "text" || x === "image") : ["text"],
      cost: { ...ZERO_COST },
    };
    if (typeof record.contextWindow === "number") model.contextWindow = record.contextWindow;
    if (typeof record.maxTokens === "number") model.maxTokens = record.maxTokens;
    if (record.thinkingLevelMap && typeof record.thinkingLevelMap === "object") {
      model.thinkingLevelMap = record.thinkingLevelMap as PiModel["thinkingLevelMap"];
    }
    models.push(model);
  }
  return models;
}

function readStoredModels(): PiModel[] {
  try {
    const store = JSON.parse(readFileSync(join(homedir(), ".pi/agent/models-store.json"), "utf8")) as {
      cliproxy?: { models?: unknown };
    };
    return sanitize(store.cliproxy?.models);
  } catch {
    return [];
  }
}

function toPiModel(entry: Record<string, any>, traeOutputCaps: ReadonlyMap<string, number>): PiModel | null {
  const id = typeof entry.slug === "string" ? entry.slug : entry.id;
  if (typeof id !== "string" || MEDIA_MODEL_PATTERN.test(id)) return null;
  if (entry.visibility && entry.visibility !== "list") return null;

  const efforts = Array.isArray(entry.supported_reasoning_levels)
    ? entry.supported_reasoning_levels.map((level: any) => level?.effort).filter((effort: unknown): effort is string => typeof effort === "string")
    : [];

  const model: PiModel = {
    id,
    name: typeof entry.display_name === "string" && entry.display_name ? entry.display_name : id,
    reasoning: true,
    input: Array.isArray(entry.input_modalities)
      ? entry.input_modalities.filter((modality: unknown) => modality === "text" || modality === "image")
      : ["text"],
    cost: { ...ZERO_COST },
  };
  if (typeof entry.context_window === "number") model.contextWindow = entry.context_window;

  const outputCap = traeOutputCaps.get(id) ?? (typeof entry.max_tokens === "number" ? entry.max_tokens : undefined);
  if (outputCap) model.maxTokens = outputCap;

  if (efforts.length > 0) {
    const map: Record<string, string | null> = { off: null };
    for (const level of PI_THINKING_LEVELS) map[level] = efforts.includes(level) ? level : null;
    model.thinkingLevelMap = map;
  }
  return model;
}

async function fetchWithTimeout(url: string, signal: AbortSignal, headers?: Record<string, string>): Promise<Response> {
  return fetch(url, { headers, signal: AbortSignal.any([signal, AbortSignal.timeout(FETCH_TIMEOUT_MS)]) });
}

async function fetchCatalog(signal: AbortSignal): Promise<PiModel[]> {
  const [codexResponse, traeResponse] = await Promise.all([
    fetchWithTimeout(`${PROXY_URL}/models?client_version=${CLIENT_VERSION}`, signal, {
      authorization: `Bearer ${PROXY_KEY}`,
    }),
    // The Trae loopback ignores auth and only supplements output-token caps; its absence is fine.
    fetchWithTimeout(`${TRAE_URL}/models`, signal).catch(() => null),
  ]);
  if (!codexResponse.ok) throw new Error(`CLIProxyAPI catalog returned HTTP ${codexResponse.status}`);

  const traeOutputCaps = new Map<string, number>();
  if (traeResponse?.ok) {
    const traeCatalog = (await traeResponse.json()) as { data?: Array<{ id?: string; max_completion_tokens?: number }> };
    for (const model of traeCatalog.data ?? []) {
      if (typeof model.id === "string" && typeof model.max_completion_tokens === "number") {
        traeOutputCaps.set(model.id, model.max_completion_tokens);
      }
    }
  }

  const codexCatalog = (await codexResponse.json()) as { models?: Array<Record<string, any>> };
  return (codexCatalog.models ?? [])
    .map((entry) => toPiModel(entry, traeOutputCaps))
    .filter((model): model is PiModel => model !== null);
}

export default function registerCliproxyCatalog(pi: ExtensionAPI) {
  pi.registerProvider("cliproxy", {
    name: "CLIProxyAPI",
    baseUrl: PROXY_URL,
    apiKey: PROXY_KEY,
    api: "openai-completions",
    // Synchronous cache read avoids a zero-model race while headless mode starts.
    models: readStoredModels(),
    refreshModels: async (context: any) => {
      const stored = sanitize(context.stored?.models);
      // Phase 1 is cache-only; only hit localhost when there is nothing to restore.
      if (!context.allowNetwork && stored.length > 0) return stored;
      if (process.env.PI_OFFLINE !== undefined) return stored;
      try {
        const models = await fetchCatalog(context.signal as AbortSignal);
        if (models.length === 0 || context.signal.aborted) return stored;
        await context.publish({ persist: { models, checkedAt: Date.now() } });
        return models;
      } catch {
        // Both proxies unreachable: keep the persisted snapshot.
        return stored;
      }
    },
  });
}
