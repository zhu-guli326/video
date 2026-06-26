$ErrorActionPreference = "Stop"

$obsConfig = Join-Path $env:APPDATA "obs-studio"
$targetScripts = Join-Path $obsConfig "scripts"
$targetScript = Join-Path $targetScripts "screen-studio-lite.lua"
$targetAssets = Join-Path $targetScripts "screen-studio-lite"

if (Get-Process -Name obs64 -ErrorAction SilentlyContinue) {
    throw "Please close OBS before uninstalling Screen Studio Lite."
}

if (Test-Path -LiteralPath $targetScript) {
    Remove-Item -LiteralPath $targetScript -Force
}

if (Test-Path -LiteralPath $targetAssets) {
    Remove-Item -LiteralPath $targetAssets -Recurse -Force
}

Write-Host "Removed Screen Studio Lite files from OBS scripts folder."
