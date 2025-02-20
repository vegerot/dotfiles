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

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete # make tab work like bash

#oh-my-posh init pwsh | Invoke-Expression
