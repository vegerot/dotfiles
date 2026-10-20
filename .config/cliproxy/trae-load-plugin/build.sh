#!/bin/sh
set -eu
cd "$(dirname "$0")"
plugin_dir="${CLIPROXY_PLUGIN_DIR:-$HOME/.cli-proxy-api/plugins}"
mkdir -p "$plugin_dir"
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
go build -buildmode=c-shared -o "$build_dir/trae-load.dylib" .
# Replace the inode; never overwrite a library that may be mapped by the host.
cp "$build_dir/trae-load.dylib" "$plugin_dir/.trae-load.dylib.new"
mv -f "$plugin_dir/.trae-load.dylib.new" "$plugin_dir/trae-load.dylib"
