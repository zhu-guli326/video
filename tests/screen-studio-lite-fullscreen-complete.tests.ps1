$scriptPath = Join-Path $PSScriptRoot "..\scripts\screen-studio-lite.lua"
$script = Get-Content -Raw $scriptPath

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        throw $Message
    }
}

function Assert-NotContains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -match $Pattern) {
        throw $Message
    }
}

Assert-Contains $script 'studio_exclude_taskbar\s*=\s*false,' 'Expected fullscreen reset to default to complete screen capture without taskbar crop.'
Assert-Contains $script 'obs\.obs_data_set_default_bool\(settings,\s*"studio_exclude_taskbar",\s*false\)' 'Expected OBS default to keep full screen capture uncropped.'
Assert-NotContains $script 'not\s+obs\.obs_data_has_user_value\(settings,\s*"studio_exclude_taskbar"\)(?s:.*?)settings_state\.studio_exclude_taskbar\s*=\s*true' 'Expected missing taskbar-crop settings not to be forced back on.'

$zoomFromState = [regex]::Match($script, 'function\s+zoom_from_state_point\(state,\s*label,\s*zoom_override\)(?s:.*?)\nend')
if (-not $zoomFromState.Success) {
    throw 'Expected zoom_from_state_point function to exist.'
}
Assert-Contains $zoomFromState.Value 'should_exclude_taskbar\(state\)' 'Expected click zoom coordinate scaling to follow the same fullscreen-safe taskbar decision.'

$followZoom = [regex]::Match($script, 'function\s+follow_zoom_to_pointer\(state\)(?s:.*?)\nend')
if (-not $followZoom.Success) {
    throw 'Expected follow_zoom_to_pointer function to exist.'
}
Assert-Contains $followZoom.Value 'should_exclude_taskbar\(state\)' 'Expected pointer-follow zoom to use the fullscreen-safe taskbar decision.'

Write-Output "Screen Studio Lite fullscreen completeness tests passed."
