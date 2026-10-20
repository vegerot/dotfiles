#!/usr/bin/env bash
# Antigravity CLI -> Atuin hook bridge
# Transforms Antigravity JSON hook events into Atuin's expected wire format.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$PATH"

exit_success() {
  if [ "$EVENT" = "PreToolUse" ]; then
    echo '{"decision":"allow"}'
  else
    echo "{}"
  fi
  exit 0
}

command -v jq >/dev/null 2>&1 || exit_success
command -v atuin >/dev/null 2>&1 || exit_success

EVENT="${1:-PreToolUse}"
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.toolCall.name // empty' 2>/dev/null | tr -d "\015" || true)
if [ "$TOOL_NAME" != "run_command" ]; then
  exit_success
fi

CONV_ID=$(echo "$INPUT" | jq -r '.conversationId // "agy"' 2>/dev/null | tr -d "\015" || echo "agy")
STEP_IDX=$(echo "$INPUT" | jq -r '.stepIdx // 0' 2>/dev/null | tr -d "\015" || echo "0")
TOOL_USE_ID="${CONV_ID}_${STEP_IDX}"

if [ "$EVENT" = "PreToolUse" ]; then
  CMD=$(echo "$INPUT" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null | tr -d "\015" || true)
  if [ -n "$CMD" ]; then
    (
      jq -n \
        --arg tid "$TOOL_USE_ID" \
        --arg cmd "$CMD" \
        '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_use_id: $tid, tool_input: {command: $cmd}}' \
        | atuin hook claude-code
    ) </dev/null >/dev/null 2>&1 &
  fi
elif [ "$EVENT" = "PostToolUse" ]; then
  ERR=$(echo "$INPUT" | jq -r '.error // empty' 2>/dev/null | tr -d "\015" || true)
  EV_NAME="PostToolUse"
  [ -n "$ERR" ] && EV_NAME="PostToolUseFailure"
  (
    jq -n \
      --arg ev "$EV_NAME" \
      --arg tid "$TOOL_USE_ID" \
      '{hook_event_name: $ev, tool_name: "Bash", tool_use_id: $tid, tool_response: "done"}' \
      | atuin hook claude-code
  ) </dev/null >/dev/null 2>&1 &
fi

exit_success
