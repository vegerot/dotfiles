<#
.SYNOPSIS
    Clone Google, Gemini, Chrome, and Antigravity repositories in parallel on Windows.
.DESCRIPTION
    Mirrors clone.sh for Windows PowerShell. Shallow clones Google and related
    reference repositories in parallel via HTTPS into the current working directory.
.PARAMETER ThrottleLimit
    Maximum number of concurrent clone operations (defaults to 8).
#>
[CmdletBinding()]
param(
    [int]$ThrottleLimit = 8
)

$ErrorActionPreference = "Stop"

$repos = @(
    @{ Dir = "antigravity-cli"; Url = "https://github.com/google-antigravity/antigravity-cli.git" }
    @{ Dir = "antigravity-sdk-python"; Url = "https://github.com/google-antigravity/antigravity-sdk-python.git" }
    @{ Dir = "chrome-devtools-mcp"; Url = "https://github.com/ChromeDevTools/chrome-devtools-mcp.git" }
    @{ Dir = "chrome-extensions-samples"; Url = "https://github.com/GoogleChrome/chrome-extensions-samples.git" }
    @{ Dir = "computer-use-preview"; Url = "https://github.com/google-gemini/computer-use-preview.git" }
    @{ Dir = "devtools-frontend"; Url = "https://github.com/ChromeDevTools/devtools-frontend.git" }
    @{ Dir = "devtools-protocol"; Url = "https://github.com/ChromeDevTools/devtools-protocol.git" }
    @{ Dir = "gemini-android-computer-use-quickstart"; Url = "https://github.com/google-gemini/gemini-android-computer-use-quickstart.git" }
    @{ Dir = "gemini-api-cli"; Url = "https://github.com/google-gemini/gemini-api-cli.git" }
    @{ Dir = "gemini-api-examples"; Url = "https://github.com/google-gemini/api-examples.git" }
    @{ Dir = "gemini-cli"; Url = "https://github.com/google-gemini/gemini-cli.git" }
    @{ Dir = "gemini-cookbook"; Url = "https://github.com/google-gemini/cookbook.git" }
    @{ Dir = "gemini-skills"; Url = "https://github.com/google-gemini/gemini-skills.git" }
    @{ Dir = "mcp"; Url = "https://github.com/google/mcp.git" }
    @{ Dir = "modern-web-guidance"; Url = "https://github.com/GoogleChrome/modern-web-guidance.git" }
    @{ Dir = "modern-web-guidance-src"; Url = "https://github.com/GoogleChrome/modern-web-guidance-src.git" }
    @{ Dir = "proxy-to-gemini"; Url = "https://github.com/google-gemini/proxy-to-gemini.git" }
    @{ Dir = "samples"; Url = "https://github.com/GoogleChrome/samples.git" }
    @{ Dir = "skills"; Url = "https://github.com/google/skills.git" }
    @{ Dir = "styleguide"; Url = "https://github.com/google/styleguide.git" }
    @{ Dir = "web-vitals"; Url = "https://github.com/GoogleChrome/web-vitals.git" }
    @{ Dir = "web-vitals-extension"; Url = "https://github.com/vegerot/web-vitals-extension.git" }
    @{ Dir = "workspace-cli"; Url = "https://github.com/googleworkspace/cli.git" }
)

$baseDir = (Get-Location).Path

Write-Host "Cloning $($repos.Count) repositories in parallel via HTTPS..."

$results = $repos | ForEach-Object -Parallel {
    $dir = $_.Dir
    $url = $_.Url
    $dirPath = Join-Path $using:baseDir $dir

    if (Test-Path -LiteralPath $dirPath) {
        Write-Host "⏩ [$dir] already exists, skipping."
        return [PSCustomObject]@{ Dir = $dir; Status = "Skipped" }
    }

    if ($dir -eq "workspace-cli" -and (Test-Path -LiteralPath (Join-Path $using:baseDir "googleworkspace-cli"))) {
        Write-Host "⏩ [$dir] found existing googleworkspace-cli, creating junction..."
        $targetPath = (Resolve-Path -LiteralPath (Join-Path $using:baseDir "googleworkspace-cli")).Path
        New-Item -ItemType Junction -Path $dirPath -Target $targetPath | Out-Null
        Write-Host "✅ [$dir -> googleworkspace-cli] Junction created!"
        return [PSCustomObject]@{ Dir = $dir; Status = "Success" }
    }

    Write-Host "⏳ [$dir] Cloning from $url..."
    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    try {
        $proc = Start-Process -FilePath "git" `
            -ArgumentList @("clone", "--depth", "1", $url, $dir) `
            -WorkingDirectory $using:baseDir `
            -NoNewWindow `
            -PassThru `
            -Wait `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile

        if ($proc.ExitCode -eq 0) {
            Write-Host "✅ [$dir] Done!"
            return [PSCustomObject]@{ Dir = $dir; Status = "Success" }
        } else {
            $err = Get-Content -LiteralPath $stderrFile -Raw -ErrorAction SilentlyContinue
            Write-Host "❌ [$dir] Failed to clone!`n$err" -ForegroundColor Red
            return [PSCustomObject]@{ Dir = $dir; Status = "Failed"; Error = $err }
        }
    } finally {
        Remove-Item -LiteralPath $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    }
} -ThrottleLimit $ThrottleLimit

$failed = ($results | Where-Object { $_.Status -eq "Failed" }).Count
if ($failed -eq 0) {
    Write-Host "🎉 All repositories shallow cloned successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Completed with $failed failure(s)." -ForegroundColor Yellow
    exit 1
}
