#!/usr/bin/env bash
# Claude Code status line — mirrors Max's zsh prompt style
# Reads JSON from stdin and prints a single status line.

input=$(cat)

# --- Flux Island quota cache ---
# Flux Island reads this file to show Claude limits. Was previously done by
# ~/.flux/bin/flux-statusline, which we no longer call (it used a login shell).
_rl=$(echo "$input" | jq -c '.rate_limits // empty' 2>/dev/null)
[ -n "$_rl" ] && printf '%s\n' "$_rl" > '/tmp/flux-rl.json'

# --- Claude context info ---
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# --- Identity (mirrors 🪪%n 💻%m) ---
user=$(whoami)
host=$(hostname -s)

# --- Directory (mirrors 📁%3~/) ---
if [ -n "$cwd" ]; then
  # Shorten to last 3 path components, replacing $HOME with ~
  home_escaped=$(printf '%s\n' "$HOME" | sed 's/[[\.*^$()+?{|]/\\&/g')
  short_dir=$(echo "$cwd" | sed "s|^$home_escaped|~|")
  # Keep only last 3 components
  short_dir=$(echo "$short_dir" | awk -F'/' '{
    n=NF; if(n<=3) print $0;
    else { out=$(n-2)"/"$(n-1)"/"$n; print ".../"out }
  }')
else
  short_dir="$(pwd | sed "s|^$HOME|~|")"
fi

# --- Git branch (mirrors 🌿<branch>) ---
branch=""
if git -C "${cwd:-$(pwd)}" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "${cwd:-$(pwd)}" --no-optional-locks branch --show-current 2>/dev/null)
  [ -n "$branch" ] && branch="🌿 $branch"
fi

# --- Context usage bar ---
ctx_part=""
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  ctx_part=" ctx:${used_int}%"
fi

# --- Rate limits (Claude.ai subscribers only) ---
rate_part=""
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five" ]; then
  rate_part="$rate_part 5h:$(printf '%.0f' "$five")%"
fi
if [ -n "$week" ]; then
  rate_part="$rate_part 7d:$(printf '%.0f' "$week")%"
fi

# --- Assemble line (ANSI colors, dimmed-terminal friendly) ---
# Green for identity, blue for path, magenta for branch, cyan for model
printf '\033[32m🪪 %s\033[0m 💻\033[32m%s\033[0m: \033[34m📁 %s\033[0m' \
  "$user" "$host" "$short_dir"

[ -n "$branch" ] && printf ' \033[35m%s\033[0m' "$branch"
[ -n "$model"  ] && printf ' \033[36m[%s]\033[0m' "$model"
[ -n "$ctx_part"  ] && printf '\033[33m%s\033[0m' "$ctx_part"
[ -n "$rate_part" ] && printf '\033[33m%s\033[0m' "$rate_part"
printf '\n'
