# PowerShell profile
# Loaded by: $PROFILE
#   Windows profiles are regular dot-source stubs because OneDrive cannot back up symlinks.
#   ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
#   ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
#   macOS/Linux: ~/.config/powershell/Microsoft.PowerShell_profile.ps1

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete # make tab work like bash

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

$randomCowCommand = Join-Path $HOME 'dotfiles\bin\randomcowcommand.ps1'
if (Test-Path -LiteralPath $randomCowCommand) {
  & $randomCowCommand
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

$secretsFile = "$env:USERPROFILE\.secrets.env.ps1"
if (Test-Path $secretsFile) { . $secretsFile }

#oh-my-posh init pwsh | Invoke-Expression
