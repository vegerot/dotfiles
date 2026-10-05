# PowerShell port of bin/findrepo.
$ErrorActionPreference = 'Stop'
$Root = Join-Path $HOME 'code'
$Filter = ''
if ($args.Count -gt 0 -and $args[0] -in '--root', '-Root') {
  if ($args.Count -lt 2) {
    throw 'Usage: findrepo [--root DIRECTORY] [FILTER]'
  }
  $Root = $args[1]
  $args = @($args | Select-Object -Skip 2)
}
if ($args.Count -gt 1) {
  throw 'Usage: findrepo [--root DIRECTORY] [FILTER]'
}
if ($args.Count -eq 1) { $Filter = $args[0] }

# Include .git and .sl files so linked worktrees and submodules are repositories too.
$metadata = & fd '^\.(git|sl)$' $Root --no-ignore --max-depth=5 --hidden --follow --prune --absolute-path
if ($LASTEXITCODE -ne 0) {
  throw "findrepo: fd failed with exit code $LASTEXITCODE"
}

$metadata |
  ForEach-Object { Split-Path -Parent $_.TrimEnd('\', '/') } |
  Sort-Object -Unique |
  Where-Object { -not $Filter -or $_ -match $Filter }
