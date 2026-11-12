#!/usr/bin/env zsh
# Claude Code status line — mirrors Max's zsh prompt style.
# Reads JSON from stdin and prints a single status line.
# Run as "zsh -f": it needs nothing from ~/.zshenv, and skipping it is faster.

# One jq call turns the fields we need into shell assignments. @sh quotes each
# value, so the eval is safe. A missing field becomes an empty string.
eval "$(jq --raw-output '@sh "
  model=\(.model.display_name // "")
  cwd=\(.workspace.current_dir // .cwd // "")
  used_pct=\(.context_window.used_percentage // "")
  effort=\(.effort.level // "")
  cost=\(.cost.total_cost_usd // "")
  five=\(.rate_limits.five_hour.used_percentage // "")
  week=\(.rate_limits.seven_day.used_percentage // "")
  rate_limits=\((.rate_limits | values | tojson) // "")"')"

# Flux Island reads this file to show Claude limits.
[[ -n $rate_limits ]] && print -r -- $rate_limits > /tmp/flux-rl.json

# --- Directory (mirrors 📁%3~/): ~ for $HOME, then the last 3 components ---
# Windows gives C:\Users\Max\x. Make it /c/Users/Max/x so $HOME matches.
cwd=${cwd//\\//}
[[ $cwd == [A-Za-z]:/* ]] && cwd=/${(L)cwd[1]}${cwd[3,-1]}
short_dir=${${cwd:-$PWD}/#$HOME/\~}
parts=("${(@s:/:)short_dir}")
[[ -n $cwd ]] && (( $#parts > 3 )) && short_dir=.../${(j:/:)parts[-3,-1]}

# --- Git branch (mirrors 🌿<branch>); empty outside a repository ---
branch=$(git -C ${cwd:-$PWD} --no-optional-locks branch --show-current 2>/dev/null)

# --- Emoji tiers ---
# Effort: only present when the current model supports reasoning effort.
typeset -A effort_emojis=(low 🥱 medium 🤔 high 🧠 xhigh 🤓 max 🤯)
effort_emoji=${effort_emojis[$effort]:-❔}
# Session cost (list-price estimate; on a subscription nothing is billed).
if [[ -n $cost ]]; then
  if   (( cost < 1 ));  then cost_emoji=🪙
  elif (( cost < 5 ));  then cost_emoji=💵
  elif (( cost < 20 )); then cost_emoji=💸
  else                       cost_emoji=🔥
  fi
fi

# --- Assemble line (ANSI colors, dimmed-terminal friendly) ---
# Green for identity (mirrors 🪪%n 💻%m), blue for path, magenta for branch,
# cyan for model and effort, yellow for context, cost, and rate limits
# (rate limits exist for Claude.ai subscribers only).
green=$'\e[32m' yellow=$'\e[33m' blue=$'\e[34m' magenta=$'\e[35m' cyan=$'\e[36m' reset=$'\e[0m'
line="${green}🪪 ${USERNAME}${reset} 💻${green}${HOST%%.*}${reset}: ${blue}📁 ${short_dir}${reset}"
[[ -n $branch   ]] && line+=" ${magenta}🌿 ${branch}${reset}"
[[ -n $model    ]] && line+=" ${cyan}[${model}]${reset}"
[[ -n $effort   ]] && line+=" ${cyan}${effort_emoji} ${effort}${reset}"
[[ -n $used_pct ]] && line+="${yellow} ctx:$(printf '%.0f' $used_pct)%${reset}"
[[ -n $cost     ]] && line+="${yellow} ${cost_emoji}\$$(printf '%.2f' $cost)${reset}"
rates=""
[[ -n $five ]] && rates+=" 5h:$(printf '%.0f' $five)%"
[[ -n $week ]] && rates+=" 7d:$(printf '%.0f' $week)%"
[[ -n $rates ]] && line+="${yellow}${rates}${reset}"
print -r -- $line
