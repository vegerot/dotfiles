#!/bin/bash
set -euo pipefail

# ─── ANSI Helpers (Standard 16-color palette only) ───────────────────────────
R="\033[0m"         # Reset
B="\033[1m"         # Bold
D="\033[2m"         # Dim
I="\033[3m"         # Italic

# Foreground accents (Standard 16 colors)
FG_BLACK="\033[30m"
FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

FG_GRAY="\033[90m"
FG_BRIGHT_RED="\033[91m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_YELLOW="\033[93m"
FG_BRIGHT_BLUE="\033[94m"
FG_BRIGHT_MAGENTA="\033[95m"
FG_BRIGHT_CYAN="\033[96m"
FG_BRIGHT_WHITE="\033[97m"

# Number Highlight Color
NUM_COLOR="${FG_BRIGHT_WHITE}${B}"

# ─── Parse JSON from stdin (Single jq pass for performance) ──────────────────
# Extract all fields in one pass to prevent spawning jq multiple times.
{
  read -r STATE
  read -r USED_PCT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r SANDBOX
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r COLS
  read -r CWD
} <<< "$(
  jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.sandbox.enabled // false),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.terminal_width // 80),
    (.workspace.current_dir // .cwd // "")
  ' 2>/dev/null | tr -d "\015" || printf "idle\n0\n\nfalse\nfalse\n0\n0\n0\n80\n\n"
)"

# ─── Computed Values ─────────────────────────────────────────────────────────
# Use LC_NUMERIC=C to prevent bash printf errors in locales that use commas for decimals
PCT_FMT=$(LC_NUMERIC=C printf "%.1f" "$USED_PCT")
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}

# ─── State Indicator (No background colors) ──────────────────────────────────
case "$STATE" in
  idle)     S="${FG_BRIGHT_GREEN}${B}● READY${R}" ;;
  thinking) S="${FG_BRIGHT_YELLOW}${B}◆ THINKING${R}" ;;
  working)  S="${FG_BRIGHT_CYAN}${B}⚙ WORKING${R}" ;;
  tool_use) S="${FG_BRIGHT_MAGENTA}${B}🔧 TOOL${R}" ;;
  *)        S="${FG_WHITE}${B}⏳ $(echo "$STATE" | tr '[:lower:]' '[:upper:]')${R}" ;;
esac

# ─── Identity & Directory ───────────────────────────────────────────────────
USER_NAME=$(whoami)
HOST_NAME=$(hostname | cut -d. -f1)

TARGET_DIR="${CWD:-$(pwd)}"
# Windows gives C:\Users\Max\x. Make it /c/Users/Max/x so $HOME and awk match.
TARGET_DIR=$(printf "%s" "${TARGET_DIR//\\//}" | sed 's|^\([A-Za-z]\):/|/\L\1/|')

if [ -n "$TARGET_DIR" ]; then
  # Shorten to last 3 path components, replacing $HOME with ~
  HOME_ESCAPED=$(printf '%s\n' "$HOME" | sed 's/[[\.*^$()+?{|]/\\&/g')
  SHORT_DIR=$(echo "$TARGET_DIR" | sed "s|^$HOME_ESCAPED|~|")
  SHORT_DIR=$(echo "$SHORT_DIR" | awk -F'/' '{
    n=NF; if(n<=3) print $0;
    else { out=$(n-2)"/"$(n-1)"/"$n; print ".../"out }
  }')
else
  SHORT_DIR="~"
fi

ID_PATH="${FG_GRAY} ╱ ${FG_BRIGHT_GREEN}🪪 ${USER_NAME}${R} ${FG_GRAY}💻${FG_BRIGHT_GREEN}${HOST_NAME}${R}${FG_GRAY}:${R} ${FG_BRIGHT_BLUE}📁 ${SHORT_DIR}${R}"

# ─── VCS Branch & Dirty Indicator ────────────────────────────────────────────
BRANCH="$VCS_BRANCH"
DIRTY="$VCS_DIRTY"

# Fallback to local git if agy payload is empty or in detached HEAD
if [ -z "$BRANCH" ]; then
  if git -C "${TARGET_DIR}" --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "${TARGET_DIR}" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "${TARGET_DIR}" --no-optional-locks rev-parse --short HEAD 2>/dev/null || true)
    if [ -n "$BRANCH" ]; then
      if [ -n "$(git -C "${TARGET_DIR}" --no-optional-locks status --porcelain 2>/dev/null | head -n 1)" ]; then
        DIRTY="true"
      fi
    fi
  fi
fi

V=""
if [ -n "$BRANCH" ]; then
  if [ "$DIRTY" = "true" ]; then
    V="${FG_GRAY} ╱ ${FG_BRIGHT_BLUE}🌿 ${BRANCH}${FG_BRIGHT_YELLOW}*${R}"
  else
    V="${FG_GRAY} ╱ ${FG_BRIGHT_BLUE}🌿 ${BRANCH}${R}"
  fi
fi

# ─── Sandbox Badge ───────────────────────────────────────────────────────────
if [ "$SANDBOX" = "true" ]; then
  SB="${FG_GRAY}sandbox ${FG_BRIGHT_GREEN}${B}ON${R}"
else
  SB="${FG_GRAY}sandbox off${R}"
fi

# ─── Context Bar (15 segments, fine-grain Unicode) ────────────────────────────
BAR_LEN=15
FILLED=$((PCT_INT * BAR_LEN / 100))
REMAINDER=$(( (PCT_INT * BAR_LEN) % 100 ))

# Pick color based on percentage
if [ "$PCT_INT" -ge 90 ]; then
  BAR_COLOR="$FG_BRIGHT_RED"
elif [ "$PCT_INT" -ge 60 ]; then
  BAR_COLOR="$FG_BRIGHT_YELLOW"
else
  BAR_COLOR="$FG_BRIGHT_WHITE"
fi

# Build bar with partial-fill last block
BAR=""
for ((i = 0; i < BAR_LEN; i++)); do
  if [ "$i" -lt "$FILLED" ]; then
    BAR="${BAR}█"
  elif [ "$i" -eq "$FILLED" ]; then
    if [ "$REMAINDER" -ge 75 ]; then
      BAR="${BAR}▓"
    elif [ "$REMAINDER" -ge 50 ]; then
      BAR="${BAR}▒"
    elif [ "$REMAINDER" -ge 25 ]; then
      BAR="${BAR}░"
    else
      BAR="${BAR}·"
    fi
  else
    BAR="${BAR}·"
  fi
done

# ─── Stats ───────────────────────────────────────────────────────────────────
CTX="${FG_GRAY}ctx ${BAR_COLOR}${BAR} ${NUM_COLOR}${PCT_FMT}%${R}"
ART_FMT="${FG_GRAY}artifacts ${NUM_COLOR}${ARTIFACTS}${R}"
SUB_FMT="${FG_GRAY}subagents ${NUM_COLOR}${SUBAGENTS}${R}"
BG_FMT="${FG_GRAY}tasks ${NUM_COLOR}${BG_TASKS}${R}"

# ─── Separators ──────────────────────────────────────────────────────────────
DOT="${FG_GRAY} · ${R}"

# ─── Output ──────────────────────────────────────────────────────────────────
LINE1="${S}${ID_PATH}${V}"
LINE2=" ${CTX}${DOT}${ART_FMT}${DOT}${SUB_FMT}${DOT}${BG_FMT}${DOT}${SB}"

if [ "$COLS" -ge 120 ]; then
  # Wide: single line
  echo -e "${LINE1}${FG_GRAY}  │  ${R}${LINE2}"
elif [ "$COLS" -ge 80 ]; then
  # Medium: two-line layout with border
  echo -e "${FG_GRAY}╭─${R} ${LINE1}"
  echo -e "${FG_GRAY}╰─${R}${LINE2}"
else
  # Narrow: compact two-line, minimal chrome
  echo -e "${S}${V}"
  echo -e "${CTX}${DOT}${BG_FMT}"
fi
