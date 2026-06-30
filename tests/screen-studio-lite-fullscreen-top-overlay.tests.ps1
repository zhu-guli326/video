$scriptPath = Join-Path $PSScriptRoot "..\scripts\screen-studio-lite.lua"
$visualPath = Join-Path $PSScriptRoot "..\scripts\screen-studio-lite\visual-layer.html"
$script = Get-Content -Raw $scriptPath
$visual = Get-Content -Raw $visualPath

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

$restoreFunction = [regex]::Match($script, 'function\s+restore_frame_layer_tick\(\)(?s:.*?)\nend')
if (-not $restoreFunction.Success) {
    throw 'Expected restore_frame_layer_tick function to exist.'
}
Assert-Contains $restoreFunction.Value 'apply_fullscreen_round_mask\(\)' 'Expected fullscreen reset to keep the source-level rounded mask.'
Assert-Contains $restoreFunction.Value 'set_frame_layer_visible\(false\)' 'Expected fullscreen reset to keep the upper frame overlay hidden.'
Assert-NotContains $script 'set_frame_layer_visible\(true\)' 'Expected no code path to show the upper frame overlay over fullscreen capture.'

$visualLayerFunction = [regex]::Match($script, 'function\s+add_or_update_visual_layer\(\)(?s:.*?)\nend')
if (-not $visualLayerFunction.Success) {
    throw 'Expected add_or_update_visual_layer function to exist.'
}
Assert-Contains $visualLayerFunction.Value 'layer\.mode\s*==\s*"frame"(?s:.*?)obs\.obs_sceneitem_set_visible\(item,\s*false\)' 'Expected startup visual layer refresh to keep the upper frame overlay hidden.'
$frameBranch = [regex]::Match($visualLayerFunction.Value, 'elseif\s+layer\.mode\s*==\s*"frame"\s+then(?s:.*?)\n\s*else')
if (-not $frameBranch.Success) {
    throw 'Expected add_or_update_visual_layer to have a frame branch.'
}
Assert-NotContains $frameBranch.Value 'obs\.obs_sceneitem_set_visible\(item,\s*true\)' 'Expected startup visual layer refresh not to show the frame overlay.'

Assert-Contains $visual 'body\[data-mode="frame"\]\s+\.frame-matte\s*\{(?s:.*?)display:\s*none;' 'Expected frame-mode browser layer to stay transparent.'
Assert-NotContains $visual 'body\[data-mode="frame"\]\s+\.frame-matte\s*\{(?s:.*?)display:\s*block;' 'Expected frame-mode browser layer not to draw a matte over the top of fullscreen capture.'

Write-Output "Screen Studio Lite fullscreen top overlay tests passed."
