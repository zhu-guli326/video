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

Assert-Contains $script 'click_reset_delay_ms\s*=\s*3000,' 'Expected mouse-idle fullscreen reset to default to 3000ms.'
Assert-Contains $script 'obs\.obs_data_set_default_int\(settings,\s*"click_reset_delay_ms",\s*3000\)' 'Expected OBS default setting for 3000ms mouse-idle fullscreen reset.'
Assert-Contains $script 'obs\.obs_properties_add_int_slider\(props,\s*"click_reset_delay_ms",\s*"Mouse Idle Fullscreen Delay \(ms\)",\s*0,\s*3000,\s*50\)' 'Expected OBS settings panel to expose the 3 second idle-fullscreen delay.'

$scheduleFunction = [regex]::Match($script, 'function\s+schedule_click_reset\(item,\s*zoom_duration_ms\)(?s:.*?)\nend')
if (-not $scheduleFunction.Success) {
    throw 'Expected schedule_click_reset function to exist.'
}
Assert-Contains $scheduleFunction.Value 'idle_ms\s*=\s*hold_ms' 'Expected scheduled reset to keep a mouse-idle delay.'
Assert-Contains $scheduleFunction.Value 'last_activity_ms\s*=\s*math\.max\(last_pointer_activity_ms\s*or\s*0,\s*ready_ms\)' 'Expected scheduled reset to wait for the latest pointer activity.'

$resetTickFunction = [regex]::Match($script, 'function\s+click_reset_tick\(\)(?s:.*?)\nend')
if (-not $resetTickFunction.Success) {
    throw 'Expected click_reset_tick function to exist.'
}
Assert-Contains $resetTickFunction.Value 'last_pointer_activity_ms\s*or\s*0' 'Expected reset tick to observe mouse movement.'
Assert-Contains $resetTickFunction.Value 'now_ms\(\)\s*-\s*last_activity_ms\)\s*<\s*idle_ms' 'Expected reset tick to wait until the mouse is idle.'
Assert-Contains $resetTickFunction.Value 'enqueue_animation\(item,\s*original,\s*reset_duration,\s*"reset"\)' 'Expected mouse idle to animate back to the full-screen transform.'

$cursorUpdateFunction = [regex]::Match($script, 'function\s+update_cursor_scene_item\(state\)(?s:.*?)\nend')
if (-not $cursorUpdateFunction.Success) {
    throw 'Expected update_cursor_scene_item function to exist.'
}
Assert-Contains $cursorUpdateFunction.Value 'pending_click_reset\.last_activity_ms\s*=\s*now' 'Expected mouse movement to postpone the fullscreen reset.'

Assert-Contains $script 'settings_state\.click_reset_delay_ms\s*=\s*obs\.obs_data_get_int\(settings,\s*"click_reset_delay_ms"\)(?s:.*?)settings_state\.click_reset_delay_ms\s*>\s*3000(?s:.*?)settings_state\.click_reset_delay_ms\s*=\s*3000(?s:.*?)obs\.obs_data_set_int\(settings,\s*"click_reset_delay_ms",\s*settings_state\.click_reset_delay_ms\)' 'Expected existing saved delays above 3000ms to migrate to the new 3 second behavior.'

Write-Output "Screen Studio Lite mouse idle fullscreen tests passed."
