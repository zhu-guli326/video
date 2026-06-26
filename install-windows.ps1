$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceScripts = Join-Path $packageRoot "scripts"
$obsConfig = Join-Path $env:APPDATA "obs-studio"
$targetScripts = Join-Path $obsConfig "scripts"
$targetScript = Join-Path $targetScripts "screen-studio-lite.lua"
$targetAssets = Join-Path $targetScripts "screen-studio-lite"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (Get-Process -Name obs64 -ErrorAction SilentlyContinue) {
    throw "Please close OBS before installing Screen Studio Lite."
}

if (-not (Test-Path -LiteralPath $obsConfig)) {
    throw "OBS config folder was not found at $obsConfig. Install and open OBS once first."
}

New-Item -ItemType Directory -Force -Path $targetScripts | Out-Null

if (Test-Path -LiteralPath $targetScript) {
    Copy-Item -LiteralPath $targetScript -Destination "$targetScript.bak-$stamp" -Force
}

if (Test-Path -LiteralPath $targetAssets) {
    Copy-Item -LiteralPath $targetAssets -Destination "$targetAssets.bak-$stamp" -Recurse -Force
}

Copy-Item -LiteralPath (Join-Path $sourceScripts "screen-studio-lite.lua") -Destination $targetScript -Force
Copy-Item -LiteralPath (Join-Path $sourceScripts "screen-studio-lite") -Destination $targetAssets -Recurse -Force

$userIni = Join-Path $obsConfig "user.ini"
if (Test-Path -LiteralPath $userIni) {
    Copy-Item -LiteralPath $userIni -Destination "$userIni.bak-screen-studio-lite-$stamp" -Force
    $lines = Get-Content -LiteralPath $userIni
    $out = New-Object System.Collections.Generic.List[string]
    $inBasicWindow = $false
    $seenBasicWindow = $false
    $wrote = $false

    foreach ($line in $lines) {
        if ($line -match '^\[(.+)\]$') {
            if ($inBasicWindow -and -not $wrote) {
                $out.Add("HideOBSWindowsFromCapture=true")
                $wrote = $true
            }
            $inBasicWindow = ($Matches[1] -eq "BasicWindow")
            if ($inBasicWindow) {
                $seenBasicWindow = $true
            }
            $out.Add($line)
            continue
        }

        if ($inBasicWindow -and $line -match '^HideOBSWindowsFromCapture=') {
            $out.Add("HideOBSWindowsFromCapture=true")
            $wrote = $true
        } else {
            $out.Add($line)
        }
    }

    if ($inBasicWindow -and -not $wrote) {
        $out.Add("HideOBSWindowsFromCapture=true")
        $wrote = $true
    }

    if (-not $seenBasicWindow) {
        $out.Add("")
        $out.Add("[BasicWindow]")
        $out.Add("HideOBSWindowsFromCapture=true")
    }

    Set-Content -LiteralPath $userIni -Value $out -Encoding UTF8
}

Write-Host ""
Write-Host "Installed Screen Studio Lite to:"
Write-Host $targetScript
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Open OBS normally."
Write-Host "2. Go to Tools > Scripts."
Write-Host "3. Add this script if it is not already listed:"
Write-Host "   $targetScript"
Write-Host "4. In the script panel, click 'Create Full Studio Setup'."
Write-Host ""
