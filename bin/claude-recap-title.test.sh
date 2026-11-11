#!/usr/bin/env bash
# Tests for claude-recap-title. They run the script the way Claude Code does:
# hook JSON on stdin, a fixture transcript on disk, and they read stdout.
# The only fake is `claude` itself (the call to Haiku), replaced by a stub on PATH.
# Run: bin/claude-recap-title.test.sh
script="$(dirname "$0")/claude-recap-title"
failures=0

setup() {
  tmp=$(mktemp --directory)
  export XDG_STATE_HOME="$tmp/state"
  transcript="$tmp/transcript.jsonl"
  # Stub namer: records each call and its stdin, then prints a fixed title.
  mkdir "$tmp/bin"
  cat > "$tmp/bin/claude" <<STUB
#!/usr/bin/env bash
cat >> "$tmp/namer-stdin"
echo call >> "$tmp/namer-calls"
sleep "\${STUB_SLEEP:-0}"
echo "\${STUB_TITLE-Recap title hook}"
exit "\${STUB_EXIT:-0}"
STUB
  chmod +x "$tmp/bin/claude"
  PATH="$tmp/bin:$PATH"
}

hook() { # hook <mode>: run the script with the hook input Claude Code sends
  jq --null-input --arg transcript "$transcript" \
    '{session_id: "session-1", transcript_path: $transcript, hook_event_name: "UserPromptSubmit", prompt: "next prompt"}' \
    | "$script" "$1"
}

check() { # check <name> <actual> <expected>
  if [[ $2 == "$3" ]]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "       expected: $3"; echo "       actual:   $2"; failures=$((failures + 1)); fi
}

test_apply_prints_nothing_when_no_name_is_pending() {
  setup
  check "apply prints nothing when no name is pending" "$(hook apply)" ""
}

recap() { # recap <uuid> <text>: append a session recap line, as Claude Code writes it
  jq --null-input --compact-output --arg uuid "$1" --arg text "$2" \
    '{type: "system", subtype: "away_summary", content: $text, uuid: $uuid, sessionId: "session-1"}' >> "$transcript"
}

title_json() { # the hook output that sets the session title
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"%s"}}' "$1"
}

test_recap_is_named_and_applied_as_the_session_title() {
  setup
  recap recap-1 "Building a hook that renames the session after each recap. Next: wire it into settings."
  hook generate
  check "after a recap, apply prints the name as the session title" "$(hook apply)" "$(title_json "Recap title hook")"
}

test_a_name_is_applied_only_once() {
  setup
  recap recap-1 "Building a hook."
  hook generate
  hook apply > /dev/null
  check "a name is applied only once" "$(hook apply)" ""
}

namer_calls() { [[ -e $tmp/namer-calls ]] && wc --lines < "$tmp/namer-calls" || echo 0; }

test_a_recap_is_named_only_once() {
  setup
  recap recap-1 "Building a hook."
  hook generate
  hook generate
  check "a recap is named only once" "$(namer_calls)" "1"
}

test_a_session_without_a_recap_is_not_named() {
  setup
  echo '{"type":"user","message":{"role":"user","content":"hello there"},"uuid":"u1"}' > "$transcript"
  hook generate
  check "a session without a recap is not named" "$(namer_calls)" "0"
}

test_a_newer_recap_is_named_from_its_own_text() {
  setup
  recap recap-1 "Building a hook."
  hook generate
  hook apply > /dev/null
  recap recap-2 "Planning a winter trip."
  hook generate
  check "a newer recap gets a name too" "$(hook apply)" "$(title_json "Recap title hook")"
  check "the namer reads the newest recap's text" "$(tail --lines 1 "$tmp/namer-stdin")" "Planning a winter trip."
}

test_the_namers_own_prompt_does_not_start_another_naming() {
  setup
  recap recap-1 "Building a hook."
  # The namer is itself a `claude` run, so it fires this hook again with the marker variable set.
  CLAUDE_RECAP_TITLE_NAMING=1 hook generate
  check "the namer's own prompt does not start another naming" "$(namer_calls)" "0"
}

test_a_failed_naming_sets_no_title() {
  setup
  recap recap-1 "Building a hook."
  STUB_TITLE="" hook generate
  check "a failed naming sets no title" "$(hook apply)" ""
}

test_a_second_prompt_during_naming_does_not_name_again() {
  setup
  recap recap-1 "Building a hook."
  STUB_SLEEP=1 hook generate &
  sleep 0.3 # the first naming is now in flight
  hook generate
  wait
  check "a second prompt during naming does not name again" "$(namer_calls)" "1"
}

test_an_error_message_from_the_namer_is_not_used_as_a_title() {
  setup
  recap recap-1 "Building a hook."
  STUB_TITLE="Not logged in · Please run /login" STUB_EXIT=1 hook generate
  check "an error message from the namer is not used as a title" "$(hook apply)" ""
}

manual_recap() { # manual_recap <uuid> <text>: append the output of a typed /recap, as Claude Code writes it
  jq --null-input --compact-output --arg uuid "$1" --arg text "$2" \
    '{type: "system", subtype: "local_command", content: "<local-command-stdout>\($text)</local-command-stdout>",
      uuid: $uuid, commandRun: {command: "recap", args: ""}}' >> "$transcript"
}

test_a_typed_recap_command_is_named_too() {
  setup
  recap recap-1 "Building a hook."
  manual_recap recap-2 "Baking sourdough bread."
  hook generate
  check "a typed /recap is named too" "$(hook apply)" "$(title_json "Recap title hook")"
  check "the namer reads the typed recap's text without its tags" "$(tail --lines 1 "$tmp/namer-stdin")" "Baking sourdough bread."
}

automatic_title() { echo "{\"type\":\"ai-title\",\"aiTitle\":\"$1\",\"sessionId\":\"session-1\"}" >> "$transcript"; }
custom_title() { echo "{\"type\":\"custom-title\",\"customTitle\":\"$1\",\"sessionId\":\"session-1\"}" >> "$transcript"; }

test_the_namer_is_told_the_current_title() {
  setup
  automatic_title "Prompt cache explanation"
  recap recap-1 "Baking sourdough bread."
  hook generate
  check "the namer is told the current title" "$(head --lines 1 "$tmp/namer-stdin")" "Current name: Prompt cache explanation"
}

test_a_custom_title_is_the_current_title_even_when_the_automatic_one_is_written_later() {
  setup
  automatic_title "Prompt cache explanation"
  custom_title "Sourdough timing"
  automatic_title "Prompt cache explanation" # Claude Code writes the automatic title again from time to time
  recap recap-1 "Baking sourdough bread."
  hook generate
  check "a custom title counts as the current title" "$(head --lines 1 "$tmp/namer-stdin")" "Current name: Sourdough timing"
}

test_an_unchanged_name_is_not_applied_again() {
  setup
  custom_title "Sourdough timing"
  recap recap-1 "Baking sourdough bread, still."
  STUB_TITLE="Sourdough timing" hook generate
  check "an unchanged name is not applied again" "$(hook apply)" ""
}

for test in $(declare -F | awk '{print $3}' | rg '^test_'); do $test; done
exit $((failures > 0))
