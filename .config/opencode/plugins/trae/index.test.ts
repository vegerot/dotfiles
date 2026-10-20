import { expect, test } from "bun:test"
import plugin from "./index"
import serverPlugin from "./server"

test("merged package exposes the Trae server plugin from both index.ts and server.ts", () => {
  expect(plugin.id).toBe("trae.provider")
  expect(typeof plugin.setup).toBe("function")
  expect(serverPlugin.id).toBe("trae.provider")
  expect(typeof serverPlugin.setup).toBe("function")
})
