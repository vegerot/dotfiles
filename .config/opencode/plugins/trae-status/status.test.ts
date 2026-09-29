import { describe, expect, test } from "bun:test"
import { footerStatus, formatTraeStatus, isTraeModel, parseTraeStatus, readTraeStatus } from "./status"

describe("Trae status", () => {
  test("parses shared weekly quota and per-model load", () => {
    const status = parseTraeStatus([
      {
        name: "GPT-5.6-Sol",
        _meta: { trae: { load: { percent: 25 } } },
      },
      {
        name: "openrouter-2o",
        _meta: {
          trae: {
            weeklyQuota: {
              applies: true,
              isDepleted: false,
              usedPercent: 20,
              remainingPercent: 80,
              resetTime: 1_791_129_599,
            },
          },
        },
      },
    ])

    expect(status).toEqual({
      models: [
        { name: "GPT-5.6-Sol", loadPercent: 25 },
        { name: "openrouter-2o", weeklyQuotaApplies: true },
      ],
      weeklyQuota: {
        remainingPercent: 80,
        resetTime: 1_791_129_599,
      },
    })
  })

  test("formats the complete cached status", () => {
    const status = parseTraeStatus([
      { name: "GPT-5.6-Sol", _meta: { trae: { load: { percent: 25 } } } },
      {
        name: "openrouter-2o",
        _meta: {
          trae: {
            weeklyQuota: {
              applies: true,
              isDepleted: false,
              usedPercent: 20,
              remainingPercent: 80,
              resetTime: 1_791_129_599,
            },
          },
        },
      },
    ])

    expect(formatTraeStatus(status, "UTC")).toBe(
      [
        "Weekly: 80% left, resets Oct 4 at 3:59 PM",
        "",
        "Model load:",
        "GPT-5.6-Sol  25%",
      ].join("\n"),
    )
  })

  test("refreshes only when explicitly requested", async () => {
    const calls: string[][] = []
    const run = async (args: readonly string[]) => {
      calls.push([...args])
      return args[0] === "models"
        ? JSON.stringify([{ name: "GPT-5.6-Sol", _meta: { trae: { load: { percent: 25 } } } }])
        : ""
    }

    await readTraeStatus(run, false)
    expect(calls).toEqual([["models", "--json"]])

    calls.length = 0
    await readTraeStatus(run, true)
    expect(calls).toEqual([
      ["debug", "models", "--remote"],
      ["models", "--json"],
    ])
  })

  test("enables Trae work only for the Trae provider", () => {
    expect(isTraeModel({ providerID: "trae" })).toBeTrue()
    expect(isTraeModel({ providerID: "openai" })).toBeFalse()
    expect(isTraeModel(undefined)).toBeFalse()
  })

  test("renders only for selected Trae models", () => {
    const status = parseTraeStatus([
      { name: "GPT-5.6-Sol", _meta: { trae: { load: { percent: 25 } } } },
      {
        name: "openrouter-2o",
        _meta: {
          trae: {
            weeklyQuota: {
              applies: true,
              isDepleted: false,
              usedPercent: 20,
              remainingPercent: 80,
            },
          },
        },
      },
    ])

    expect(footerStatus({ providerID: "trae", modelID: "GPT-5.6-Sol-Max" }, status)).toBe("Trae load 25%")
    expect(footerStatus({ providerID: "trae", modelID: "openrouter-2o-Max" }, status)).toBe("Trae weekly 80% left")
    expect(footerStatus({ providerID: "openai", modelID: "GPT-5.6-Sol" }, status)).toBeUndefined()
    expect(footerStatus(undefined, status)).toBeUndefined()
  })
})
