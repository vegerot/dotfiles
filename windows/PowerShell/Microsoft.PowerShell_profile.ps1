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
# prompt
function prompt {
  $loc = $executionContext.SessionState.Path.CurrentLocation;

  $out = "PS $loc$('>' * ($nestedPromptLevel + 1)) ";
  if ($loc.Provider.Name -eq "FileSystem") {
    $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
  }
  return $out
}

Set-Alias sap sl.exe
Set-Alias pilot "$env:LOCALAPPDATA\Voidstar\FilePilot\FPilot.exe"

$randomCowCommand = Join-Path $HOME 'dotfiles\bin\randomcowcommand.ps1'
if (Test-Path -LiteralPath $randomCowCommand) {
  & $randomCowCommand
}

#oh-my-posh init pwsh | Invoke-Expression
