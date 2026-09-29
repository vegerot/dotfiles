import { Plugin } from "@opencode/plugin/tui"
import { createEffect, createSignal, Show } from "solid-js"
import { footerStatus, formatTraeStatus, isTraeModel, readTraeStatus, type TraeStatus } from "./status"

const traex = async (args: readonly string[]) => {
  const executable = Bun.which("traex")
  if (!executable) throw new Error("`traex` is not on PATH")
  const capture = args[0] === "models"
  const process = Bun.spawn([executable, ...args], { stdout: capture ? "pipe" : "ignore", stderr: "pipe" })
  const [exitCode, stdout, stderr] = await Promise.all([
    process.exited,
    capture ? new Response(process.stdout).text() : "",
    new Response(process.stderr).text(),
  ])
  if (exitCode !== 0) throw new Error(stderr.trim() || `traex exited with ${exitCode}`)
  return stdout
}

export default Plugin.define({
  id: "trae.status",
  setup(context) {
    const [status, setStatus] = createSignal<TraeStatus>()
    let loaded = false

    const load = async (refresh: boolean) => {
      const next = await readTraeStatus(traex, refresh)
      setStatus(next)
      return next
    }

    context.ui.slot({
      append: "prompt.footer.status",
      render: () => {
        createEffect(() => {
          if (!isTraeModel(context.ui.model.current()) || loaded) return
          loaded = true
          void load(false).catch(() => {
            loaded = false
          })
        })
        const text = () => footerStatus(context.ui.model.current(), status())
        return (
          <Show when={text()}>
            {(value) => (
              <text fg={context.theme.text.muted} wrapMode="none" flexShrink={0}>
                · {value()}
              </text>
            )}
          </Show>
        )
      },
    })

    context.ui.slot({
      append: "app",
      render: () => {
        context.keymap.layer(() => ({
          mode: "global",
          commands: [
            {
              id: "trae.status.show",
              title: "Show Trae quota and model load",
              description: "Reads cached Trae status; pass `refresh` to fetch current status first",
              group: "Trae",
              palette: true,
              slash: { name: "trae-status", arguments: true },
              enabled: () => isTraeModel(context.ui.model.current()),
              async run(input) {
                const refresh = input?.trim() === "refresh"
                if (input?.trim() && !refresh) {
                  context.ui.toast.show({ message: "Usage: /trae-status [refresh]", variant: "warning" })
                  return
                }
                const next = await load(refresh).catch((cause: unknown) => {
                  const message = cause instanceof Error ? cause.message : String(cause)
                  context.ui.toast.show({ title: "Trae status", message, variant: "error" })
                })
                if (!next) return
                await context.ui.dialog.alert({
                  title: refresh ? "Trae status · refreshed" : "Trae status",
                  message: formatTraeStatus(next),
                })
              },
            },
          ],
        }))
        return null
      },
    })

    return () => {
      setStatus(undefined)
    }
  },
})
