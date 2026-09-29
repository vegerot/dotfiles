import { expect, test } from "bun:test"
import plugin from "./index"

test("merged package exposes the Trae server plugin", () => {
  expect(plugin.id).toBe("trae.provider")
  expect(typeof plugin.setup).toBe("function")
})
