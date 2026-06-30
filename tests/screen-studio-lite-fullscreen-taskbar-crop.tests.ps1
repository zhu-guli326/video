$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "..\scripts\screen-studio-lite.lua"
$script = Get-Content -LiteralPath $scriptPath -Raw
$helperPath = Join-Path $PSScriptRoot "..\scripts\screen-studio-lite\click-zoom-helper.ps1"
$helperScript = Get-Content -LiteralPath $helperPath -Raw

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

Assert-Contains $script 'function\s+should_exclude_taskbar\(state\)' 'Expected a shared should_exclude_taskbar helper.'
Assert-Contains $script 'function\s+foreground_window_is_fullscreen\(state\)' 'Expected a foreground fullscreen detector.'

$helper = [regex]::Match($script, 'function\s+should_exclude_taskbar\(state\)(?s:.*?)\nend')
if (-not $helper.Success) {
    throw 'Expected should_exclude_taskbar helper to exist.'
}
if ($helper.Value -match 'fixed_bottom_blank_space(?s:.*?)return\s+false') {
    throw 'Expected fixed bottom blank space not to disable taskbar exclusion.'
}
Assert-Contains $helper.Value 'foreground_window_is_fullscreen\(state\)' 'Expected foreground fullscreen state to disable taskbar exclusion.'
Assert-Contains $helper.Value 'return\s+false' 'Expected fullscreen foreground windows not to be taskbar-cropped.'
Assert-Contains $helper.Value 'return\s+settings_state\.studio_exclude_taskbar' 'Expected taskbar exclusion to follow the OBS script setting.'

$applyFunction = [regex]::Match($script, 'function\s+apply_taskbar_crop_to_zoom_target\(state\)(?s:.*?)\nend')
if (-not $applyFunction.Success) {
    throw 'Expected apply_taskbar_crop_to_zoom_target function to exist.'
}
Assert-Contains $applyFunction.Value 'if\s+not\s+should_exclude_taskbar\(state\)\s+then' 'Expected taskbar crop reset to use should_exclude_taskbar(state).'
Assert-Contains $script 'if\s+not\s+should_exclude_taskbar\(state\)\s+then(?s:.*?)obs\.obs_sceneitem_set_crop\(item,\s*crop\)(?s:.*?)upsert_round_mask_for_scene_item\(item\)(?s:.*?)last_taskbar_crop_signature\s*=\s*""' 'Expected taskbar crop reset branch to refresh the rounded mask before clearing its signature.'

$captureFunction = [regex]::Match($script, 'click_capture_area\s*=\s*function\(state\)(?s:.*?)\nend')
if (-not $captureFunction.Success) {
    throw 'Expected click_capture_area function to exist.'
}
Assert-Contains $captureFunction.Value 'if\s+should_exclude_taskbar\(state\)\s+then' 'Expected click capture area to use should_exclude_taskbar(state).'

Assert-Contains $helperScript 'GetWindowRect' 'Expected helper to read the foreground window rectangle.'
Assert-Contains $helperScript 'foreground_fullscreen=' 'Expected helper state file to report foreground_fullscreen.'

Write-Output "Screen Studio Lite fullscreen taskbar crop tests passed."
