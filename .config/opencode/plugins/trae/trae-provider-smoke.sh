#!/bin/sh
set -eu

model=${OPENCODE_TRAE_SMOKE_MODEL:-trae/GPT-5.6-Sol}
marker="OPENCODE_TRAE_SMOKE_$$"
workspace=$(mktemp -d "${TMPDIR:-/tmp}/opencode-trae-smoke.XXXXXX")
trap 'rm -rf "$workspace"' EXIT INT TERM

printf 'live smoke: text generation\n'
text=$(opencode run --model "$model" --format json "Reply with exactly: $marker")
printf '%s\n' "$text" | grep -F "$marker" >/dev/null

printf 'live smoke: tool round trip\n'
tool=$(
  cd "$workspace"
  opencode run --model "$model" --format json \
    "Use the shell tool to run touch trae-tool-ok, then reply with exactly: $marker"
)
printf '%s\n' "$tool" | grep -F "$marker" >/dev/null
test -f "$workspace/trae-tool-ok"

printf 'live smoke: long-context progress notices\n'
long_prompt=$(awk 'BEGIN { for (i = 0; i < 12000; i++) printf "context-%d ", i }')
long=$(opencode run --model "$model" --format json "$long_prompt\nReply with exactly: $marker")
printf '%s\n' "$long" | grep -F "$marker" >/dev/null

printf 'Trae smoke checks passed for %s\n' "$model"
