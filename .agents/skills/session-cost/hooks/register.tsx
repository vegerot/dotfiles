import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

// The status line shows cost in the terminal only. This band shows it wherever
// the session is drawn (terminal, desktop, VS Code, mobile), and names the surface,
// so it doubles as a check of which hosts draw a mod at all.
const usd = atom({ plugin: 'session-cost', key: 'usd' } as const, null)
const hasLedger = atom({ plugin: 'session-cost', key: 'hasLedger' } as const, true)

async function refresh($: EngineInterface) {
  const { cost } = await $.session.usage()
  await update($, usd, () => cost?.usd ?? null)
  await update($, hasLedger, () => cost !== undefined)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    await refresh($)
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const dollars = await read($, usd)
    const label = !(await read($, hasLedger))
      ? 'no cost ledger on this host'
      : dollars === null
        ? 'cost after the first turn'
        : `$${dollars.toFixed(2)} this session`
    return (
      <Box>
        <Text dimColor>💸 {label} · {e.surface}</Text>
      </Box>
    )
  })
}
