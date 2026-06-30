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

Assert-Contains $script 'fixed_bottom_blank_space\s*=\s*500' 'Expected default fixed_bottom_blank_space to be 500.'
Assert-Contains $script 'capture_vertical_anchor\s*=\s*0\.42' 'Expected default capture_vertical_anchor to center the capture slightly upward.'
Assert-Contains $script 'function\s+layout_canvas_area\(\)' 'Expected a layout_canvas_area helper.'
Assert-Contains $script 'function\s+capture_layout_y\(' 'Expected a capture_layout_y helper.'
Assert-Contains $script 'obs\.obs_properties_add_int\(props,\s*"fixed_bottom_blank_space"' 'Expected a script property for Fixed Bottom Blank Space.'
Assert-Contains $script 'obs\.obs_properties_add_float_slider\(props,\s*"capture_vertical_anchor"' 'Expected a script property for Capture Vertical Anchor.'
Assert-Contains $script 'obs\.obs_data_set_default_int\(settings,\s*"fixed_bottom_blank_space",\s*500\)' 'Expected OBS default setting for 500px bottom blank space.'
Assert-Contains $script 'obs\.obs_data_set_default_double\(settings,\s*"capture_vertical_anchor",\s*0\.42\)' 'Expected OBS default setting for upward-centered capture anchor.'
Assert-Contains $script 'settings_state\.fixed_bottom_blank_space\s*=\s*obs\.obs_data_get_int\(settings,\s*"fixed_bottom_blank_space"\)' 'Expected settings_state to read the bottom blank space setting.'
Assert-Contains $script 'settings_state\.capture_vertical_anchor\s*=\s*obs\.obs_data_get_double\(settings,\s*"capture_vertical_anchor"\)' 'Expected settings_state to read the capture vertical anchor setting.'

$fitFunction = [regex]::Match($script, 'fit_item_to_canvas_area\s*=\s*function\(item, preserve_aspect, crop_to_bounds\)(?s:.*?)\nend')
if (-not $fitFunction.Success) {
    throw 'Expected fit_item_to_canvas_area function to exist.'
}
Assert-Contains $fitFunction.Value 'layout_canvas_area\(\)' 'Expected fit_item_to_canvas_area to use layout_canvas_area.'
Assert-Contains $fitFunction.Value 'target\.pos_y\s*=\s*capture_layout_y\(layout_y,\s*layout_height,\s*target_height\)' 'Expected fit layout to use the upward-centered capture anchor.'

$zoomFunction = [regex]::Match($script, 'function\s+zoom_transform_for_source_point\(base, source_x, source_y, source_width, source_height, base_free_scale, zoom_override\)(?s:.*?)\nend')
if (-not $zoomFunction.Success) {
    throw 'Expected zoom_transform_for_source_point function to exist.'
}
Assert-Contains $zoomFunction.Value 'layout_canvas_area\(\)' 'Expected zoom_transform_for_source_point to use layout_canvas_area.'
Assert-Contains $zoomFunction.Value 'focus_y\s*=\s*layout_y\s*\+\s*\(layout_height\s*\*\s*0\.5\)' 'Expected zoom focus to stay inside the reduced layout height.'
Assert-Contains $zoomFunction.Value 'clamp_zoom_y_to_layout\(pos_y,\s*scaled_height,\s*layout_height,\s*layout_y\)' 'Expected zoom y-axis clamping to preserve bottom blank space.'

Write-Output "Screen Studio Lite bottom blank space tests passed."
