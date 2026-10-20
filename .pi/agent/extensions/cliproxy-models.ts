// Dynamic CLIProxyAPI catalog for Pi. Discovery and normalization are shared
// with OpenCode in .config/cliproxy/catalog.ts; Pi owns persistence and thinking
// level mapping. Restore the snapshot synchronously for headless startup.

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

import { type CatalogModel, fetchCatalog, preferTraeMax, PROXY_URL, PROXY_KEY } from "../../../.config/cliproxy/catalog";

// Pi thinking levels in picker order. Catalog efforts not in this list (e.g. "ultra") are dropped.
const PI_THINKING_LEVELS = ["minimal", "low", "medium", "high", "xhigh", "max"] as const;

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
  // Pi's persisted snapshot omits ownership. Trae Max IDs are generated as
  // <model>-Max; retain other providers' model names as supplied by the catalog.
  const traeIDs = new Set(models.filter((model) => model.id.endsWith("-Max")).map((model) => model.id.slice(0, -4)));
  return preferTraeMax(models, traeIDs);
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

function toPiModel(entry: CatalogModel): PiModel {
  const model: PiModel = {
    id: entry.id,
    name: entry.name,
    // Some fixed-effort models reason without offering selectable levels.
    reasoning: true,
    input: entry.input,
    cost: { ...ZERO_COST },
  };
  if (entry.context) model.contextWindow = entry.context;
  if (entry.output) model.maxTokens = entry.output;
  if (entry.reasoning.length > 0) {
    model.thinkingLevelMap = { off: null };
    for (const level of PI_THINKING_LEVELS) {
      model.thinkingLevelMap[level] = entry.reasoning.includes(level) ? level : null;
    }
  }
  return model;
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
        const models = (await fetchCatalog(context.signal as AbortSignal)).map(toPiModel);
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
