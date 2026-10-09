#!/usr/bin/env bash
set -euo pipefail
# Target directory defaults to ~/code/github.com/google or $1
TARGET_DIR="${1:-${TARGET_DIR:-$HOME/code/github.com/google}}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# List of target directory and HTTPS remote URL pairs
repos=(
  "antigravity-cli|https://github.com/google-antigravity/antigravity-cli.git"
  "antigravity-sdk-python|https://github.com/google-antigravity/antigravity-sdk-python.git"
  "chrome-devtools-mcp|https://github.com/ChromeDevTools/chrome-devtools-mcp.git"
  "chrome-extensions-samples|https://github.com/GoogleChrome/chrome-extensions-samples.git"
  "computer-use-preview|https://github.com/google-gemini/computer-use-preview.git"
  "devtools-frontend|https://github.com/ChromeDevTools/devtools-frontend.git"
  "devtools-protocol|https://github.com/ChromeDevTools/devtools-protocol.git"
  "gemini-android-computer-use-quickstart|https://github.com/google-gemini/gemini-android-computer-use-quickstart.git"
  "gemini-api-cli|https://github.com/google-gemini/gemini-api-cli.git"
  "gemini-api-examples|https://github.com/google-gemini/api-examples.git"
  "gemini-cli|https://github.com/google-gemini/gemini-cli.git"
  "gemini-cookbook|https://github.com/google-gemini/cookbook.git"
  "gemini-skills|https://github.com/google-gemini/gemini-skills.git"
  "mcp|https://github.com/google/mcp.git"
  "modern-web-guidance|https://github.com/GoogleChrome/modern-web-guidance.git"
  "modern-web-guidance-src|https://github.com/GoogleChrome/modern-web-guidance-src.git"
  "proxy-to-gemini|https://github.com/google-gemini/proxy-to-gemini.git"
  "samples|https://github.com/GoogleChrome/samples.git"
  "skills|https://github.com/google/skills.git"
  "styleguide|https://github.com/google/styleguide.git"
  "web-vitals|https://github.com/GoogleChrome/web-vitals.git"
  "web-vitals-extension|https://github.com/vegerot/web-vitals-extension.git"
  "workspace-cli|https://github.com/googleworkspace/cli.git"
)

echo "Cloning ${#repos[@]} repositories in parallel via HTTPS..."

pids=()
for entry in "${repos[@]}"; do
  dir="${entry%%|*}"
  url="${entry##*|}"

  if [ -d "$dir" ]; then
    echo "⏩ [$dir] already exists, skipping."
    continue
  fi

  (
    echo "⏳ [$dir] Cloning from $url..."
    if err=$(git clone --depth 1 "$url" "$dir" 2>&1); then
      echo "✅ [$dir] Done!"
    else
      echo "❌ [$dir] Failed to clone!" >&2
      echo "$err" >&2
      exit 1
    fi
  ) &
  pids+=($!)
done

# Wait for all background clones to complete
failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=$((failed + 1))
  fi
done

if [ "$failed" -eq 0 ]; then
  echo "🎉 All repositories shallow cloned successfully!"
else
  echo "⚠️ Completed with $failed failure(s)." >&2
  exit 1
fi
