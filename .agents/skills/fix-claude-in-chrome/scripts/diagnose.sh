#!/usr/bin/env bash
# Read-only diagnosis of the Claude in Chrome native-messaging pipe.
# Makes no changes. Prints a verdict with the exact repair commands.
set -uo pipefail

EXT_ID_DEFAULT=fcoeoabgfenejglbffodgkkbkcdhcgfn
TILDE="~"   # replacement string; a bare ~ would tilde-expand back to $HOME
ok()   { printf '  ✅ %s\n' "$*"; }
bad()  { printf '  ❌ %s\n' "$*"; }
info() { printf '  ·  %s\n' "$*"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }

FAULTS=()
fault() { FAULTS+=("$1"); }

# ---------------------------------------------------------------- launcher
head_ "1. Launcher and installed versions"

LAUNCHER=$(command -v claude 2>/dev/null)
# A cmux/tmux shim in a temp dir is not the real launcher; prefer the stable one.
STABLE_LAUNCHER=""
for cand in "$HOME/.local/bin/claude" "$HOME/.claude/local/claude"; do
  [ -x "$cand" ] && { STABLE_LAUNCHER=$cand; break; }
done

if [ -n "$STABLE_LAUNCHER" ]; then
  LAUNCHER_TARGET=$(readlink "$STABLE_LAUNCHER" 2>/dev/null || echo "$STABLE_LAUNCHER")
  ok "stable launcher: ${STABLE_LAUNCHER/#$HOME/$TILDE} -> ${LAUNCHER_TARGET##*/}"
else
  bad "no stable launcher at ~/.local/bin/claude or ~/.claude/local/claude"
  fault no-launcher
fi
[ -n "$LAUNCHER" ] && [ "$LAUNCHER" != "$STABLE_LAUNCHER" ] && \
  info "PATH claude is a shim: ${LAUNCHER/#$HOME/$TILDE} (cmux/tmux wrapper — do not pin to it)"

# ------------------------------------------------------------ host wrapper
head_ "2. Native host wrapper"

WRAPPER="$HOME/.claude/chrome/chrome-native-host"
WRAPPER_TARGET=""
if [ -f "$WRAPPER" ]; then
  WRAPPER_TARGET=$(sed -n 's/^exec "\([^"]*\)".*/\1/p' "$WRAPPER" | head -1)
  [ -x "$WRAPPER" ] && ok "exists and is executable" || { bad "exists but is NOT executable"; fault wrapper-not-exec; }
  info "execs: ${WRAPPER_TARGET/#$HOME/$TILDE}"

  if [ ! -e "$WRAPPER_TARGET" ]; then
    bad "that binary is GONE — the pinned version was removed by an update"
    fault version-drift
  elif [ -n "$STABLE_LAUNCHER" ]; then
    # Compare what the wrapper runs against what the user runs.
    W_REAL=$(readlink "$WRAPPER_TARGET" 2>/dev/null || echo "$WRAPPER_TARGET")
    L_REAL=$(readlink "$STABLE_LAUNCHER" 2>/dev/null || echo "$STABLE_LAUNCHER")
    if [ "$W_REAL" = "$L_REAL" ]; then
      ok "matches the launcher version"
      case "$WRAPPER_TARGET" in
        */versions/*) info "pinned to an exact version — will drift on the next update" ;;
        *)            ok "points at the launcher symlink — survives updates" ;;
      esac
    else
      bad "VERSION DRIFT: wrapper runs ${W_REAL##*/}, launcher runs ${L_REAL##*/}"
      fault version-drift
    fi
  fi
else
  bad "missing — 'claude --chrome' has never generated it"
  fault no-wrapper
fi

# --------------------------------------------------------- browser catalog
head_ "3. Browser directories, manifests and extension"

MANIFEST_NAME=com.anthropic.claude_code_browser_extension.json
case "$(uname -s)" in
  Darwin) AS="$HOME/Library/Application Support"
    BROWSER_DIRS=(
      "$AS/Google/Chrome" "$AS/Google/Chrome Beta" "$AS/Google/Chrome Dev"
      "$AS/Google/Chrome Canary" "$AS/Chromium"
      "$AS/BraveSoftware/Brave-Browser" "$AS/BraveSoftware/Brave-Browser-Beta"
      "$AS/Microsoft Edge" "$AS/Microsoft Edge Beta" "$AS/Microsoft Edge Dev"
      "$AS/Arc/User Data" "$AS/Vivaldi" "$AS/com.operasoftware.Opera"
    ) ;;
  *)
    BROWSER_DIRS=(
      "$HOME/.config/google-chrome" "$HOME/.config/google-chrome-beta"
      "$HOME/.config/google-chrome-unstable" "$HOME/.config/chromium"
      "$HOME/.config/BraveSoftware/Brave-Browser"
      "$HOME/.config/microsoft-edge" "$HOME/.config/microsoft-edge-dev"
      "$HOME/.config/vivaldi" "$HOME/.config/opera"
    ) ;;
esac

# The manifest names the extension it trusts. Prefer that over a hardcoded ID.
EXT_ID=$EXT_ID_DEFAULT
for d in "${BROWSER_DIRS[@]}"; do
  m="$d/NativeMessagingHosts/$MANIFEST_NAME"
  [ -f "$m" ] || continue
  found=$(sed -n 's|.*chrome-extension://\([a-p]\{32\}\).*|\1|p' "$m" | head -1)
  [ -n "$found" ] && { EXT_ID=$found; break; }
done
info "extension id: $EXT_ID"

MANIFEST_SRC=""; EXT_BROWSERS=(); MANIFEST_BROWSERS=()
printf '\n  %-34s %-10s %s\n' "BROWSER" "MANIFEST" "EXTENSION"
for d in "${BROWSER_DIRS[@]}"; do
  [ -d "$d" ] || continue
  label=${d/#$HOME/$TILDE}; label=${label/Library\/Application Support\//}; label=${label/.config\//}

  has_manifest=no
  if [ -e "$d/NativeMessagingHosts/$MANIFEST_NAME" ]; then
    has_manifest=yes; MANIFEST_BROWSERS+=("$d")
    # A real file (not a symlink) is the source others can link to.
    [ -f "$d/NativeMessagingHosts/$MANIFEST_NAME" ] && [ ! -L "$d/NativeMessagingHosts/$MANIFEST_NAME" ] \
      && [ -z "$MANIFEST_SRC" ] && MANIFEST_SRC="$d/NativeMessagingHosts/$MANIFEST_NAME"
  fi

  has_ext=no
  for prof in "$d"/Default "$d"/Profile\ *; do
    [ -d "$prof/Extensions/$EXT_ID" ] && { has_ext=yes; break; }
  done
  [ "$has_ext" = yes ] && EXT_BROWSERS+=("$d")

  printf '  %-34s %-10s %s\n' "$label" \
    "$([ $has_manifest = yes ] && echo '✅ yes' || echo '—')" \
    "$([ $has_ext = yes ] && echo '✅ installed' || echo '—')"
done

echo
[ ${#EXT_BROWSERS[@]} -eq 0 ] && { bad "extension not installed in ANY browser"; fault no-extension; }
[ ${#MANIFEST_BROWSERS[@]} -eq 0 ] && { bad "manifest written nowhere"; fault no-manifest; }

# The core bug: manifest and extension must live in the SAME browser.
UNSERVED=()
for b in "${EXT_BROWSERS[@]}"; do
  [ -e "$b/NativeMessagingHosts/$MANIFEST_NAME" ] || UNSERVED+=("$b")
done
if [ ${#UNSERVED[@]} -gt 0 ]; then
  for b in "${UNSERVED[@]}"; do bad "has the extension but NO manifest: ${b/#$HOME/$TILDE}"; done
  fault manifest-wrong-browser
elif [ ${#EXT_BROWSERS[@]} -gt 0 ]; then
  ok "every browser holding the extension also has the manifest"
fi

# ----------------------------------------------------------- live processes
head_ "4. Running hosts and bridge sockets"

# Match only real hosts: the executable itself must be a claude binary or the
# wrapper. A plain grep also matches this script's own shell, which would fake
# a "stale process" fault and send you chasing a repair you do not need.
HOSTS=$(ps -eo pid,command | awk '/--chrome-native-host/ && $2 ~ /claude/')
if [ -n "$HOSTS" ]; then
  while IFS= read -r line; do info "host: ${line:0:100}"; done <<<"$HOSTS"
  if [ -n "$WRAPPER_TARGET" ] && ! grep -qF "$WRAPPER_TARGET" <<<"$HOSTS"; then
    bad "a running host uses a DIFFERENT binary than the wrapper — stale process"
    fault stale-hosts
  fi
else
  info "no host running (normal — Chrome spawns one on demand)"
fi

SOCKDIR="${TMPDIR:-/tmp}/claude-mcp-browser-bridge-$(id -un)"
[ -d "$SOCKDIR" ] || SOCKDIR="/tmp/claude-mcp-browser-bridge-$(id -un)"
if [ -d "$SOCKDIR" ]; then
  orphans=0
  for s in "$SOCKDIR"/*.sock; do
    [ -e "$s" ] || continue
    pid=$(basename "$s" .sock)
    if kill -0 "$pid" 2>/dev/null; then info "socket $pid.sock — live"
    else bad "socket $pid.sock — ORPHAN, owning process is dead"; orphans=1; fi
  done
  [ $orphans = 1 ] && fault orphan-sockets
else
  info "no socket dir yet"
fi

# ------------------------------------------------------------------ verdict
head_ "VERDICT"

if [ ${#FAULTS[@]} -eq 0 ]; then
  echo "  Healthy. Nothing to repair."
  echo "  Ignore 'Extension: Not detected' in /chrome — see SKILL.md, it lies on non-stable channels."
  echo "  Confirm for real with the headless check in SKILL.md rather than trusting the panel."
  exit 0
fi

printf '  Faults: %s\n\n' "${FAULTS[*]}"
for f in "${FAULTS[@]}"; do
  case $f in
    version-drift|no-wrapper)
      cat <<'EOF'
  • Wrapper is stale or missing. Regenerate, then unpin it so updates stop breaking it:
        claude --chrome                       # regenerates the wrapper
        # then edit ~/.claude/chrome/chrome-native-host so the last line reads:
        #   exec "$HOME/.local/bin/claude" --chrome-native-host
EOF
      ;;
    no-manifest)
      echo '  • No manifest anywhere. Run: claude --chrome   (the /chrome menu will NOT write it)'
      ;;
    manifest-wrong-browser)
      echo '  • Manifest is in the wrong browser. Link it into each browser listed above:'
      for b in "${UNSERVED[@]}"; do
        printf '        mkdir -p %q && ln -sf %q %q/\n' \
          "$b/NativeMessagingHosts" "${MANIFEST_SRC:-<run claude --chrome first>}" "$b/NativeMessagingHosts"
      done
      echo '    A symlink, not a copy, so it tracks whatever claude --chrome regenerates.'
      ;;
    stale-hosts|orphan-sockets)
      echo '  • Retire stale hosts so Chrome respawns them through the new wrapper:'
      echo "        pkill -f 'chrome-native-host'   # BSD pkill: -f, never --full"
      echo "        rm -f $SOCKDIR/*.sock"
      ;;
    no-extension)
      echo '  • Install the Claude extension from https://claude.ai/chrome in the browser you actually use.'
      ;;
    wrapper-not-exec)
      echo "  • chmod +x $WRAPPER"
      ;;
    no-launcher)
      echo '  • Reinstall Claude Code so ~/.local/bin/claude exists.'
      ;;
  esac
done
exit 1
