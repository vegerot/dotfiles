# Trae status

This OpenCode V2 CLI plugin shows Trae's cached operational status only while the selected provider is `trae`.

- Models with load metadata show `Trae load N%` in the prompt footer.
- Quota-limited models show `Trae weekly N% left` instead.
- `/trae-status` shows the shared weekly quota and every reported model load.
- `/trae-status refresh` asks TraeX to refresh the remote model catalog before showing it.

The plugin reads `traex models --json`, which normalizes Trae's cache into stable `load` and `weeklyQuota` fields. Cached reads take milliseconds. Fresh model metadata takes several seconds, so refresh is explicit rather than polled.

The weekly quota is account-wide and currently applies to the OpenRouter routes. Load is model-specific operational pressure and may exceed 100%; the plugin displays Trae's value without inventing thresholds.

Run the pure contract tests with:

```sh
bun test './.config/opencode/plugins/trae-status/status.test.ts'
```
