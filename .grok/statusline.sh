#!/usr/bin/env bash
# Grok Build status line. Same shape as ~/.claude/statusline-command.sh,
# plus the effort level Codex shows and the dirty mark Antigravity shows.
# Grok does not send rate limits, a pull-request number, or a sandbox flag.

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
cwd=$(printf '%s' "$cwd" | tr '\\' '/' | sed 's|^\([A-Za-z]\):/|/\L\1/|')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
branch=$(printf '%s' "$input" | jq -r '.workspace.branch // empty')
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty')
started=$(printf '%s' "$input" | jq -r '.turn.started_at_ms // empty')

user=$(whoami)
host=$(hostname | cut -d. -f1)

if [ -n "$cwd" ]; then
  home_escaped=$(printf '%s\n' "$HOME" | sed 's/[[\.*^$()+?{|]/\\&/g')
  short_dir=$(printf '%s' "$cwd" | sed "s|^$home_escaped|~|")
  short_dir=$(printf '%s' "$short_dir" | awk -F'/' '{
    n=NF; if(n<=3) print $0;
    else { out=$(n-2)"/"$(n-1)"/"$n; print ".../"out }
  }')
else
  short_dir="$(pwd | sed "s|^$HOME|~|")"
fi

repo="${cwd:-$(pwd)}"
dirty=""
if git -C "$repo" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
  if [ -z "$branch" ]; then
    branch=$(git -C "$repo" --no-optional-locks branch --show-current 2>/dev/null)
  fi
  if [ -n "$(git -C "$repo" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ]; then
    dirty="*"
  fi
fi

ctx_part=""
if [ -n "$used_pct" ]; then
  ctx_part=" ctx:$(printf '%.0f' "$used_pct")%"
fi

cost_part=""
if [ -n "$cost" ]; then
  # Same tiers as ~/.claude/statusline-command.sh: <$1 🪙, <$5 💵, <$20 💸, else 🔥.
  cost_emoji=$(awk -v c="$cost" 'BEGIN {
    if (c < 1) print "🪙";
    else if (c < 5) print "💵";
    else if (c < 20) print "💸";
    else print "🔥";
  }')
  cost_part=" ${cost_emoji}\$$(printf '%.2f' "$cost")"
fi

effort_part=""
if [ -n "$effort" ]; then
  effort_part=" · $effort"
fi

turn_part=""
if [ -n "$started" ]; then
  now=$(date +%s)
  start=$((started / 1000))
  elapsed=$((now - start))
  if [ "$elapsed" -ge 0 ] && [ "$elapsed" -lt 86400 ]; then
    turn_part=$(printf ' %d:%02d' $((elapsed / 60)) $((elapsed % 60)))
  fi
fi

printf '\033[32m🪪 %s\033[0m 💻\033[32m%s\033[0m: \033[34m📁 %s\033[0m' \
  "$user" "$host" "$short_dir"
if [ -n "$branch" ]; then
  printf ' \033[35m🌿 %s%s\033[0m' "$branch" "$dirty"
fi
if [ -n "$model" ]; then
  printf ' \033[36m[%s%s]\033[0m' "$model" "$effort_part"
fi
if [ -n "$ctx_part" ]; then
  printf '\033[33m%s\033[0m' "$ctx_part"
fi
if [ -n "$cost_part" ]; then
  printf '\033[33m%s\033[0m' "$cost_part"
fi
if [ -n "$turn_part" ]; then
  printf '\033[33m%s\033[0m' "$turn_part"
fi
printf '\n'
