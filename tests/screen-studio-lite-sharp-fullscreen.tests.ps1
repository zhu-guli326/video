$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "..\scripts\screen-studio-lite.lua"
$script = Get-Content -LiteralPath $scriptPath -Raw

function Assert-Contains {
    param(
        [string] $Text,
        [string] $Pattern,
        [string] $Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

Assert-Contains $script 'card_margin\s*=\s*0' 'Expected default card_margin to be 0 for the sharpest full-width capture.'
Assert-Contains $script 'obs\.obs_data_set_default_int\(settings,\s*"card_margin",\s*0\)' 'Expected OBS default card_margin to be 0.'
Assert-Contains $script 'settings_state\.card_margin\s*==\s*180' 'Expected old 180 px default margin to migrate to 0.'
Assert-Contains $script 'obs\.obs_data_set_int\(settings,\s*"card_margin",\s*settings_state\.card_margin\)' 'Expected migrated card_margin to persist back into OBS settings.'

$fitFunction = [regex]::Match($script, 'fit_item_to_canvas_area\s*=\s*function\(item, preserve_aspect, crop_to_bounds\)(?s:.*?)\nend')
if (-not $fitFunction.Success) {
    throw 'Expected fit_item_to_canvas_area function to exist.'
}

Assert-Contains $fitFunction.Value 'layout_width\s*-\s*\(settings_state\.card_margin\s*\*\s*2\)' 'Expected fit layout to honor the configurable side margin.'
Assert-Contains $fitFunction.Value 'layout_height\s*-\s*\(settings_state\.card_margin\s*\*\s*2\)' 'Expected fit layout to honor the configurable vertical margin.'

Write-Output "Screen Studio Lite sharp fullscreen tests passed."
