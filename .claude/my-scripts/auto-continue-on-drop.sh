#!/usr/bin/env bash
# StopFailure hook: when a turn dies with "Connection lost mid-response", post "continue"
# into this session's own inbox socket so the turn resumes without a keypress.
#
# Verified on 2.1.260 (stream-reset-after-first-block.md): a message posted from a hook
# with the session's own env vars is accepted as self-sent, wakes the idle session, and
# runs as a user turn. No hook can *reply* to the error, but a hook can *send*.
#
# Install (settings.json):
#   "StopFailure": [{"hooks": [{"type": "command", "command": "~/.claude/my-scripts/auto-continue-on-drop.sh"}]}]
# Keep it synchronous: the post must come from a live child of the session.
#
# Matching: by 2.1.316 a mid-response drop arrives with error "server_error" and
# error_details null. "Connection lost mid-response" is only the text Claude Code shows,
# so matching that alone stopped firing. Keep the old phrases for builds that fill
# error_details. A real 5xx also arrives as "server_error"; continuing is fine there too,
# and the rate cap below stops a storm.
set -u
input=$(cat)
kind=$(printf '%s' "$input" | jq -r '.error // ""')
text=$(printf '%s' "$input" | jq -r '[.error_details, .last_assistant_message] | map(select(type == "string")) | join(" ")')
# Only network and server errors. Auth, billing, and prompt-too-long errors do not get better by continuing.
case "$text" in
  *"Connection lost mid-response"*|*"Connection dropped"*|*"stopped arriving"*) ;;
  *) [ "$kind" = server_error ] || exit 0 ;;
esac
# Rate cap: at most 5 continues per 10 minutes, so a storm cannot loop forever.
stamp="${TMPDIR:-/tmp}/auto-continue.${CLAUDE_CODE_SESSION_ID:-unknown}"
now=$(date +%s); cutoff=$((now - 600))
{ [ -f "$stamp" ] && awk -v c="$cutoff" '$1 > c' "$stamp"; echo "$now"; } > "$stamp.new" && mv "$stamp.new" "$stamp"
[ "$(wc -l < "$stamp")" -gt 5 ] && exit 0
python3 - "$CLAUDE_CODE_MESSAGING_SOCKET" "$CLAUDE_CODE_MESSAGING_TOKEN" <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect(sys.argv[1])
s.sendall((json.dumps({"type": "auth", "token": sys.argv[2]}) + "\n").encode())
s.sendall((json.dumps({"type": "user", "message": {"role": "user",
    "content": "continue (auto-sent by the StopFailure hook after a dropped connection)"}}) + "\n").encode())
PY
