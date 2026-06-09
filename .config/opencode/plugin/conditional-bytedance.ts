import type { Plugin } from "@opencode-ai/plugin"
import { os } from "bun"

export default (async () => {
  return {
    config(cfg) {
      const isBytedance = os.userInfo().username === "bytedance" || cfg.username === "bytedance"
      if (isBytedance) return

      // Disable ByteDance MCPs when not the bytedance user
      if (cfg.mcp?.["Codebase"]) cfg.mcp["Codebase"].enabled = false
      if (cfg.mcp?.["Lark"]) cfg.mcp["Lark"].enabled = false
      if (cfg.mcp?.["ByteDance MCP"]) cfg.mcp["ByteDance MCP"].enabled = false
    },
  }
}) satisfies Plugin
