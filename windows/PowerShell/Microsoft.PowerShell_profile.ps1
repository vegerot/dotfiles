# PowerShell profile
# Loaded by: $PROFILE
#   Windows profiles are regular dot-source stubs because OneDrive cannot back up symlinks.
#   ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
#   ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
#   macOS/Linux: ~/.config/powershell/Microsoft.PowerShell_profile.ps1

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete # make tab work like bash

# fnm prepends the selected Node to PATH, including in one-shot shells.
if (Get-Command fnm -ErrorAction SilentlyContinue) {
  fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Start new terminals in the same directory as the current terminal
function prompt {
  $loc = $executionContext.SessionState.Path.CurrentLocation;

  $out = ""
  if ($loc.Provider.Name -eq "FileSystem") {
    $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
  }
  $out += "PS $loc$('>' * ($nestedPromptLevel + 1)) ";
  return $out
}

Set-Alias sap sl.exe
Set-Alias filepilot "$env:LOCALAPPDATA\Voidstar\FilePilot\FPilot.exe"

# Detect common AI coding harnesses:
function Set-AgentEnvVariable {
  if (-not $env:AGENT) {
    if ($env:ANTIGRAVITY_AGENT) { $env:AGENT = "antigravity" }
    elseif ($env:CODEX_THREAD_ID) { $env:AGENT = "codex" }
    elseif ($env:CLAUDECODE) { $env:AGENT = "claude" }
    elseif ($env:OPENCODE) { $env:AGENT = "opencode" }
    elseif ($env:GROK_AGENT) { $env:AGENT = "grok" }
    elseif ($env:CURSOR_AGENT) { $env:AGENT = "cursor" }
    elseif ($env:DSH_SHELL) { $env:AGENT = "deepseek" }
  }
}
Set-AgentEnvVariable

function is_agent_harness {
  [bool]($env:AGENT -or $env:ANTIGRAVITY_AGENT -or $env:CODEX_THREAD_ID -or $env:CLAUDECODE -or $env:OPENCODE -or $env:GROK_AGENT -or $env:CURSOR_AGENT -or $env:DSH_SHELL)
}

if ((is_agent_harness) -and -not $env:AGENT_SILENCE_HINTS) {
  function psmux {
    $cmd = Get-Command -CommandType Application -Name psmux.exe -ErrorAction SilentlyContinue
    if (-not $cmd) {
      $cmd = Get-Command -CommandType Application -Name psmux -ErrorAction SilentlyContinue
    }
    if (-not $cmd) {
      [Console]::Error.WriteLine("psmux: command not found")
      return
    }
    if ((is_agent_harness) -and -not $env:AGENT_SILENCE_HINTS) {
      [Console]::Error.WriteLine('user note: the psmux source code is available at `findrepo psmux`. Silence by setting `AGENT_SILENCE_HINTS=1`')
    }
    if ($MyInvocation.ExpectingInput) {
      $input | & $cmd @args
    } else {
      & $cmd @args
    }
  }
  Set-Alias psmux.exe psmux
}

# Printing anything here corrupts scp/sftp and one-shot shells, which must stay silent.
# -NonInteractive, -Command, -File and -EncodedCommand mean "run and exit" unless -NoExit is present.
$commandLineArgs = [Environment]::GetCommandLineArgs()
$hasNoExit = [bool]($commandLineArgs | Where-Object { $_ -match '^-(?:noe(?:xit)?)$' })
$oneShotSwitch = -not $hasNoExit -and [bool]($commandLineArgs |
  Where-Object { $_ -match '^-(?:noni\w*|c(?:ommand)?|f(?:ile)?|e(?:c|ncodedcommand)?)$' })
$isInteractive = -not $oneShotSwitch -and
  -not [Console]::IsInputRedirected -and
  -not [Console]::IsOutputRedirected

if ($isInteractive) {
  $randomCowCommand = Join-Path $HOME 'dotfiles\bin\randomcowcommand.ps1'
  if (Test-Path -LiteralPath $randomCowCommand) {
    & $randomCowCommand
  }
}

function Get-WeightedRandom {
  param([hashtable]$Weights)
  $pool = $Weights.GetEnumerator() | ForEach-Object { @($_.Key) * $_.Value }
  $pool | Get-Random
}

function pick_ai_cli {
  Get-WeightedRandom @{
    crush    = 1; traeIDE  = 2; codex    = 2
    gemini   = 2; copilot  = 5; claude   = 3; opencode = 4 # Copilot should be preferred on Windows
  }
}

function pick_ai_chatbot {
  Get-WeightedRandom @{
    gemini            = 4; github_copilot    = 2; grok              = 2
    chatgpt           = 2; openwebui         = 2; claude            = 2
    codex             = 1; perplexity        = 1; google_ai         = 1
    microsoft_copilot = 5; meta              = 1; deepseek          = 1
    "tako(phone)"     = 1; openrouter_chat   = 1; chatboxai         = 1
    hf_inference      = 1; kimi              = 1
  }
}

# Shell history hooks are only needed in interactive terminals.
if ($isInteractive) {
  atuin init powershell | Out-String | Invoke-Expression
}
Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

$secretsFile = "$env:USERPROFILE\.secrets.env.ps1"
if (Test-Path $secretsFile) { . $secretsFile }

#oh-my-posh init pwsh | Invoke-Expression
