# Record Codex commands when Atuin is installed.
if (-not (Get-Command atuin -ErrorAction SilentlyContinue)) {
    exit 0
}

$hookInput = [Console]::In.ReadToEnd()
if (-not $env:ATUIN_SESSION) {
    $sessionId = ($hookInput | ConvertFrom-Json).session_id -replace '[^0-9a-fA-F]', ''
    $env:ATUIN_SESSION = if ($sessionId.Length -eq 32) { $sessionId } else { atuin uuid }
}
$hookInput | atuin hook codex
exit $LASTEXITCODE
