<#
.SYNOPSIS
    Bootstrap dotfiles on Windows by creating symbolic links in $HOME.
.DESCRIPTION
    Mirrors bootstrap.sh for Windows PowerShell. Symlinks dotfiles into $HOME,
    supporting --force, --dry-run, and an -AgyOnly filter for Antigravity (AGY)
    configurations and skills.
.PARAMETER Force
    Overwrites existing files and symlinks.
.PARAMETER DryRun
    Prints the symlinks that would be created without making changes.
.PARAMETER AgyOnly
    Only links Antigravity (.gemini) config files and skills.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun,
    [switch]$AgyOnly
)

$ErrorActionPreference = "Stop"

$dotfilesDir = $PSScriptRoot
if (-not $dotfilesDir) {
    $dotfilesDir = (Get-Location).Path
}

$excludePatterns = @(
    '^\.git\\',
    '^\.sl\\',
    '^\.claude\\worktrees\\',
    '^\.DS_Store$',
    '^\.osx$',
    '^bootstrap\.sh$',
    '^bootstrap\.ps1$',
    '^brew\.sh$',
    '^AGENTS\.md$',
    '^README\.md$',
    '^LICENSE-MIT\.txt$'
)

function Get-BootstrapItems {
    param([string]$Root, [switch]$OnlyAgy)

    Get-ChildItem -Path $Root -Recurse -Force | Where-Object {
        $rel = $_.FullName.Substring($Root.Length + 1)

        # Prune .agents/skills contents (the directory itself is linked via .gemini/skills)
        if ($rel -match '^\.agents\\skills\\') { return $false }
        if ($rel -eq '.agents\skills') { return $false }

        # Only files or symlinks
        if (-not ($_.PSIsContainer -eq $false -or $_.LinkType)) { return $false }

        # Filter for AGY only if requested
        if ($OnlyAgy -and ($rel -notmatch '^\.gemini(\\.*)?$')) { return $false }

        foreach ($pat in $excludePatterns) {
            if ($rel -match $pat) { return $false }
        }

        return $true
    }
}

function Invoke-BootstrapDryRun {
    param([array]$Items)

    foreach ($item in $Items) {
        $rel = $item.FullName.Substring($dotfilesDir.Length + 1)
        $dest = Join-Path $HOME $rel
        Write-Host "$($item.FullName) -> $dest"
    }
}

function Invoke-BootstrapForce {
    param([array]$Items)

    Write-Host "Forced bootstrap: linking dotfiles..."
    foreach ($item in $Items) {
        $rel = $item.FullName.Substring($dotfilesDir.Length + 1)
        $dest = Join-Path $HOME $rel
        $parentDir = Split-Path -Parent $dest

        if (-not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # Check if parent directory itself is already a symlink pointing to the dotfiles directory
        $parentItem = Get-Item -LiteralPath $parentDir -ErrorAction SilentlyContinue
        if ($parentItem -and $parentItem.LinkType) {
            $expectedParent = Join-Path $dotfilesDir (Split-Path -Parent $rel)
            if ($parentItem.Target -eq $expectedParent) {
                Write-Host "Already linked via parent: $dest"
                continue
            }
        }

        # If destination is an existing real directory (not a symlink)
        if ((Test-Path -LiteralPath $dest) -and (-not (Get-Item -LiteralPath $dest).LinkType) -and (Get-Item -LiteralPath $dest).PSIsContainer) {
            # Backup directory if it's skills
            if ($rel -eq '.gemini\config\skills' -or $rel -eq '.gemini\skills') {
                $backupDir = "$dest.bak"
                Write-Warning "Backing up directory $dest to $backupDir"
                if (Test-Path -LiteralPath $backupDir) { Remove-Item -LiteralPath $backupDir -Recurse -Force }
                Move-Item -LiteralPath $dest -Destination $backupDir -Force
            } else {
                Write-Error "Refusing to replace directory: $dest"
                continue
            }
        }

        # Create or overwrite symlink
        Write-Host "Linking: $($item.FullName) -> $dest"
        New-Item -ItemType SymbolicLink -Path $dest -Target $item.FullName -Force | Out-Null
    }

    $homeAgents = Join-Path $HOME "AGENTS.md"
    if (Test-Path -LiteralPath $homeAgents -PathType Leaf) {
        Remove-Item -LiteralPath $homeAgents -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-BootstrapNormal {
    param([array]$Items)

    Write-Host "Normal bootstrap: linking dotfiles (skipping existing)..."
    foreach ($item in $Items) {
        $rel = $item.FullName.Substring($dotfilesDir.Length + 1)
        $dest = Join-Path $HOME $rel
        $parentDir = Split-Path -Parent $dest

        if (-not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        if (Test-Path -LiteralPath $dest) {
            $existing = Get-Item -LiteralPath $dest
            if ($existing.PSIsContainer -and -not $existing.LinkType) {
                Write-Host "Skipping existing directory: $dest"
                continue
            }
            if ($existing.LinkType -and $existing.Target -eq $item.FullName) {
                Write-Host "Already linked: $dest"
                continue
            }
            Write-Host "Skipping existing file/link: $dest"
            continue
        }

        Write-Host "Linking: $($item.FullName) -> $dest"
        New-Item -ItemType SymbolicLink -Path $dest -Target $item.FullName | Out-Null
    }

    $homeAgents = Join-Path $HOME "AGENTS.md"
    if (Test-Path -LiteralPath $homeAgents -PathType Leaf) {
        Remove-Item -LiteralPath $homeAgents -Force -ErrorAction SilentlyContinue
    }
}

$items = Get-BootstrapItems -Root $dotfilesDir -OnlyAgy:$AgyOnly

if ($DryRun) {
    Invoke-BootstrapDryRun -Items $items
} elseif ($Force) {
    Invoke-BootstrapForce -Items $items
} else {
    $shouldProceed = $false
    if ([Console]::IsInputRedirected) {
        Write-Host "Non-interactive environment: proceeding with normal mode."
        $shouldProceed = $true
    } else {
        $reply = Read-Host "This may overwrite existing files in your home directory. Are you sure? (y/n)"
        if ($reply -match '^[Yy]$') {
            $shouldProceed = $true
        }
    }

    if ($shouldProceed) {
        Invoke-BootstrapNormal -Items $items
    } else {
        Write-Host "Aborted."
    }
}
