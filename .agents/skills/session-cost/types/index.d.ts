// Dollars so far; null until the first reading.
export type Usd = number | null

declare module 'claude-code' {
  interface PluginState {
    // hasLedger is false where the host keeps no cost ledger ($.session.usage() has no cost).
    'session-cost': { usd: Usd; hasLedger: boolean }
  }
}
