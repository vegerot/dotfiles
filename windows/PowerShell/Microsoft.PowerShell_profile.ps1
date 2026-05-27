# PowerShell profile
# Symlink to: $PROFILE
#   Windows: ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
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
    gemini   = 2; claude   = 3; opencode = 4
  }
}

function pick_ai_chatbot {
  Get-WeightedRandom @{
    github_copilot    = 4; gemini            = 3; grok              = 2
    chatgpt           = 2; codex             = 1; claude            = 1
    perplexity        = 1; google_ai         = 1; microsoft_copilot = 1
    meta              = 1; deepseek          = 1; "tako(phone)"     = 1
  }
}

#oh-my-posh init pwsh | Invoke-Expression
