# Record Codex commands when Atuin is installed.
if (-not (Get-Command atuin -ErrorAction SilentlyContinue)) {
    exit 0
}
[Console]::In.ReadToEnd() | atuin hook codex
exit $LASTEXITCODE
