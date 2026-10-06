#!/usr/bin/env bash
# Read-only diagnosis of Antigravity's live Chrome DevTools / /browser connection.
# Run with --fix to automatically apply the detected one-line repair.
set -uo pipefail

TILDE="~"
ok()   { printf '  ✅ %s\n' "$*"; }
bad()  { printf '  ❌ %s\n' "$*"; }
info() { printf '  ·  %s\n' "$*"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

AUTO_FIX=0
if [ "${1:-}" = "--fix" ]; then
  AUTO_FIX=1
fi

FAULTS=()
fault() { FAULTS+=("$1"); }

OS="$(uname -s)"
IS_HEADLESS=0
if [ "$OS" = "Linux" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  IS_HEADLESS=1
fi

head_ "1. Environment & Display State"
info "Operating System: $OS"
if [ "$IS_HEADLESS" -eq 1 ]; then
  info "Display: Headless (DISPLAY and WAYLAND_DISPLAY are unset)"
else
  info "Display: Graphical environment active"
fi

head_ "2. Chrome Binary & Process Status"
CHROME_PID=""
case "$OS" in
  Darwin)
    if pgrep -f "Google Chrome Dev" >/dev/null 2>&1; then
      ok "Google Chrome Dev is running"
      CHROME_PID=$(pgrep -f "Google Chrome Dev" | head -n 1)
    elif pgrep -f "Google Chrome" >/dev/null 2>&1; then
      ok "Google Chrome (stable) is running"
      CHROME_PID=$(pgrep -f "Google Chrome" | head -n 1)
    else
      bad "Chrome is NOT running"
      fault chrome-not-running
    fi
    ;;
  Linux)
    if [ "$IS_HEADLESS" -eq 1 ]; then
      if pgrep -f "chrome.*--headless" >/dev/null 2>&1; then
        ok "Headless Chrome daemon is running"
        CHROME_PID=$(pgrep -f "chrome.*--headless" | head -n 1)
      else
        bad "Headless Chrome daemon is NOT running"
        fault headless-chrome-not-running
      fi
    else
      if pgrep -f "chrome" >/dev/null 2>&1; then
        ok "Chrome process detected"
        CHROME_PID=$(pgrep -f "chrome" | head -n 1)
      else
        bad "Chrome is NOT running"
        fault chrome-not-running
      fi
    fi
    ;;
  *)
    info "Platform $OS - checking generic Chrome processes"
    if pgrep -i "chrome" >/dev/null 2>&1; then
      ok "Chrome running"
    else
      bad "Chrome not running"
      fault chrome-not-running
    fi
    ;;
esac

head_ "3. DevToolsActivePort Discovery"
EXPECTED_PORT_FILE=""
ACTUAL_DEV_PORT_FILE=""

case "$OS" in
  Darwin)
    EXPECTED_PORT_FILE="$HOME/Library/Application Support/Google/Chrome/DevToolsActivePort"
    ACTUAL_DEV_PORT_FILE="$HOME/Library/Application Support/Google/Chrome Dev/DevToolsActivePort"

    if [ -f "$ACTUAL_DEV_PORT_FILE" ]; then
      PORT=$(head -n 1 "$ACTUAL_DEV_PORT_FILE")
      ok "Chrome Dev port file found (port: $PORT)"
      if [ -L "$EXPECTED_PORT_FILE" ] && [ "$(readlink "$EXPECTED_PORT_FILE")" = "$ACTUAL_DEV_PORT_FILE" ]; then
        ok "Symlink Google/Chrome/DevToolsActivePort -> Google Chrome Dev is intact"
      elif [ -f "$EXPECTED_PORT_FILE" ]; then
        ok "Port file exists at standard location: ${EXPECTED_PORT_FILE/#$HOME/$TILDE}"
      else
        bad "Missing symlink at standard location (${EXPECTED_PORT_FILE/#$HOME/$TILDE})"
        fault macos-port-symlink-missing
      fi
    elif [ -f "$EXPECTED_PORT_FILE" ]; then
      PORT=$(head -n 1 "$EXPECTED_PORT_FILE")
      ok "Standard Chrome port file found (port: $PORT)"
    else
      bad "No DevToolsActivePort found. Is remote debugging enabled in Chrome?"
      fault no-port-file
    fi
    ;;
  Linux)
    if [ "$IS_HEADLESS" -eq 1 ]; then
      EXPECTED_PORT_FILE="$HOME/.config/google-chrome/DevToolsActivePort"
      if [ -f "$EXPECTED_PORT_FILE" ]; then
        PORT=$(head -n 1 "$EXPECTED_PORT_FILE")
        ok "Devbox port file found at ~/.config/google-chrome/DevToolsActivePort (port: $PORT)"
      else
        bad "No DevToolsActivePort found at ${EXPECTED_PORT_FILE/#$HOME/$TILDE}"
        fault devbox-port-missing
      fi
    else
      # Check Flatpak vs Native
      FLATPAK_DIR="$HOME/.var/app/com.google.ChromeDev/config/google-chrome-unstable"
      CONFIG_DIR="$HOME/.config/google-chrome-unstable"
      if [ -d "$FLATPAK_DIR" ]; then
        info "Flatpak Chrome Dev profile detected"
        if [ -L "$CONFIG_DIR" ] && [ "$(readlink "$CONFIG_DIR")" = "$FLATPAK_DIR" ]; then
          ok "Symlink ~/.config/google-chrome-unstable -> Flatpak profile is intact"
        else
          bad "Missing Flatpak symlink at ~/.config/google-chrome-unstable"
          fault linux-flatpak-symlink-missing
        fi
      fi
    fi
    ;;
esac

head_ "4. Remote Debugging Reachability"
TEST_PORT=""
if [ -n "$EXPECTED_PORT_FILE" ] && [ -f "$EXPECTED_PORT_FILE" ]; then
  TEST_PORT=$(head -n 1 "$EXPECTED_PORT_FILE")
fi

if [ -n "$TEST_PORT" ]; then
  if curl -s --max-time 2 "http://127.0.0.1:$TEST_PORT/json/version" >/dev/null 2>&1; then
    ok "CDP endpoint reachable on http://127.0.0.1:$TEST_PORT"
  else
    bad "CDP endpoint http://127.0.0.1:$TEST_PORT is not responding"
    fault cdp-not-responding
  fi
else
  info "Port unknown; skipping HTTP probe"
fi

head_ "VERDICT"

if [ ${#FAULTS[@]} -eq 0 ]; then
  echo "  ✅ Healthy. Antigravity /browser and chrome-devtools MCP should connect cleanly."
  exit 0
fi

printf '  Faults detected: %s\n\n' "${FAULTS[*]}"

for f in "${FAULTS[@]}"; do
  case "$f" in
    macos-port-symlink-missing)
      echo "  • [macOS] Bridge Chrome Dev's port file to the default location:"
      echo "        mkdir -p \"\$HOME/Library/Application Support/Google/Chrome\""
      echo "        ln -sf \"\$HOME/Library/Application Support/Google/Chrome Dev/DevToolsActivePort\" \\"
      echo "               \"\$HOME/Library/Application Support/Google/Chrome/DevToolsActivePort\""
      if [ "$AUTO_FIX" -eq 1 ]; then
        mkdir -p "$HOME/Library/Application Support/Google/Chrome"
        ln -sf "$HOME/Library/Application Support/Google/Chrome Dev/DevToolsActivePort" \
               "$HOME/Library/Application Support/Google/Chrome/DevToolsActivePort"
        ok "Applied macOS symlink repair"
      fi
      ;;
    linux-flatpak-symlink-missing)
      echo "  • [Linux Flatpak] Map Flatpak profile to standard XDG config directory:"
      echo "        mkdir -p \"\$HOME/.config\""
      echo "        ln -sf \"\$HOME/.var/app/com.google.ChromeDev/config/google-chrome-unstable\" \\"
      echo "               \"\$HOME/.config/google-chrome-unstable\""
      if [ "$AUTO_FIX" -eq 1 ]; then
        mkdir -p "$HOME/.config"
        ln -sf "$HOME/.var/app/com.google.ChromeDev/config/google-chrome-unstable" \
               "$HOME/.config/google-chrome-unstable"
        ok "Applied Flatpak symlink repair"
      fi
      ;;
    headless-chrome-not-running|devbox-port-missing)
      echo "  • [Headless Linux / Devbox] Spawn the headless Chrome daemon:"
      echo "        nohup google-chrome \\"
      echo "          --headless=new \\"
      echo "          --remote-debugging-port=0 \\"
      echo "          --remote-allow-origins='*' \\"
      echo "          --user-data-dir=\"\$HOME/.config/google-chrome\" \\"
      echo "          --no-first-run > /dev/null 2>&1 &"
      if [ "$AUTO_FIX" -eq 1 ]; then
        nohup google-chrome \
          --headless=new \
          --remote-debugging-port=0 \
          --remote-allow-origins='*' \
          --user-data-dir="$HOME/.config/google-chrome" \
          --no-first-run > /dev/null 2>&1 &
        ok "Launched headless Chrome daemon on devbox"
      fi
      ;;
    chrome-not-running)
      echo "  • Chrome is not running. Launch Google Chrome Dev and ensure remote debugging is enabled:"
      echo "        chrome://inspect/#remote-debugging (check 'Enable remote debugging')"
      ;;
    no-port-file|cdp-not-responding)
      echo "  • Remote debugging port not active. Open Chrome and navigate to:"
      echo "        chrome://inspect/#remote-debugging"
      echo "    Ensure 'Enable remote debugging' is checked, or start Chrome with --remote-debugging-port=9222."
      ;;
  esac
done

if [ "$AUTO_FIX" -eq 1 ]; then
  echo
  info "Auto-fix executed. Re-run scripts/diagnose.sh to verify."
fi

exit 1
