# PORT of POSIX version at ./randomcowcommand
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DescriptionText {
  param(
    [Parameter()]
    [object[]]$Description,
    [Parameter(Mandatory = $true)]
    [string]$CommandName
  )

  return @(
    foreach ($item in $Description) {
      if ($null -eq $item) {
        continue
      }

      $textProperty = $item | Get-Member -Name Text -ErrorAction SilentlyContinue
      if ($null -ne $textProperty) {
        [string]$item.Text
        continue
      }

      Write-Warning ("randomcowcommand: unexpected help description item type for {0}: {1}" -f $CommandName, $item.GetType().FullName)
    }
  ) -join ' '
}

function Get-CommandSummary {
  param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.CommandInfo]$Command
  )

  try {
    $help = Get-Help -Name $Command.Name -ErrorAction Stop -ProgressAction SilentlyContinue
  }
  catch {
    return $null
  }

  $descriptionText = Get-DescriptionText -Description $help.Description -CommandName $Command.Name

  $candidates = @(
    [string]$help.Synopsis
    $descriptionText
  )

  foreach ($candidate in $candidates) {
    $summary = ($candidate -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($summary)) {
      continue
    }

    if (
      $summary.StartsWith("$($Command.Name) ") -or
      $summary -match '\[<CommonParameters>\]' -or
      $summary -match '\[-' -or
      $summary -match '<[^>]+>'
    ) {
      continue
    }

    return $summary
  }

  return $null
}

function Test-HelpAvailable {
  $testHelp = Get-Help Get-Command -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
  return ($null -ne $testHelp.Synopsis -and -not [string]::IsNullOrWhiteSpace($testHelp.Synopsis) -and $testHelp.Synopsis -notmatch '^\s*Get-Command\s')
}

function Get-RandomCommandDescription {
  if (-not (Test-HelpAvailable)) {
    return 'randomcowcommand - PowerShell help not installed. Run: Update-Help'
  }

  $commands = @(Get-Command -CommandType Cmdlet)
  foreach ($command in ($commands | Get-Random -Count 25)) {
    $summary = Get-CommandSummary -Command $command
    if ([string]::IsNullOrWhiteSpace($summary)) {
      continue
    }

    return "$($command.Name) - $summary"
  }

  return 'randomcowcommand - a script that works sometimes :('
}

function Format-Message {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  $cowsay = Get-Command -Name cowsay -ErrorAction SilentlyContinue
  if ($null -ne $cowsay) {
    return (& $cowsay.Source $Message | Out-String).TrimEnd()
  }

  return @(
    ''
    '-------------------------------'
    "Did you know: $Message"
    '-------------------------------'
    ''
  ) -join [Environment]::NewLine
}

function Get-RenderedMessage {
  $message = Format-Message -Message (Get-RandomCommandDescription)
  $rainbow = Get-Command -Name rainbow -ErrorAction SilentlyContinue
  if ($null -ne $rainbow) {
    return (& $rainbow.Source $message | Out-String).TrimEnd()
  }

  return $message
}

Get-RenderedMessage
