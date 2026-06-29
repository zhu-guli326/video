obs = obslua

local SCRIPT_DIR = script_path()
local MASK_DIR = SCRIPT_DIR .. "screen-studio-lite/masks/"
local VISUAL_LAYER_PATH = SCRIPT_DIR .. "screen-studio-lite/visual-layer.html"
local HELPER_PATH = SCRIPT_DIR .. "screen-studio-lite/click-zoom-helper.ps1"
local HELPER_LAUNCHER_PATH = SCRIPT_DIR .. "screen-studio-lite/click-zoom-helper-launch.cmd"
local CLICK_STATE_PATH = SCRIPT_DIR .. "screen-studio-lite/click-state.txt"
local CLICK_STOP_PATH = SCRIPT_DIR .. "screen-studio-lite/click-stop.flag"
local HELPER_STDOUT_PATH = SCRIPT_DIR .. "screen-studio-lite/click-zoom-helper.out.log"
local HELPER_STDERR_PATH = SCRIPT_DIR .. "screen-studio-lite/click-zoom-helper.err.log"
local CLICK_STATE_URL = "http://127.0.0.1:27987/state"
local TIMELINE_PATH = SCRIPT_DIR .. "screen-studio-lite/studio-timeline.md"
local TIMELINE_JSON_PATH = SCRIPT_DIR .. "screen-studio-lite/studio-timeline.json"
local STUDIO_EDITOR_PATH = SCRIPT_DIR .. "screen-studio-lite/studio-editor.html"
local STUDIO_PROJECT_PATH = SCRIPT_DIR .. "screen-studio-lite/studio-project.json"
local STUDIO_EXPORT_SCRIPT_PATH = SCRIPT_DIR .. "screen-studio-lite/export-video.ps1"
local STUDIO_EXPORT_CMD_PATH = SCRIPT_DIR .. "screen-studio-lite/export-video.cmd"
local LIVE_STATUS_PATH = SCRIPT_DIR .. "screen-studio-lite/live-status.json"
local DYNAMIC_MASK_SCRIPT_PATH = MASK_DIR .. "generate-dynamic-mask.ps1"
local FILTER_NAME = "Screen Studio Lite - Rounded Corners"
local VISUAL_LAYER_SOURCE_NAME = "Screen Studio Lite - Background"
local FRAME_LAYER_SOURCE_NAME = "Screen Studio Lite - Frame"
local CURSOR_LAYER_SOURCE_NAME = "Screen Studio Lite - Cursor"
CAMERA_PLACEHOLDER_SOURCE_NAME = "Screen Studio Lite - Camera Placeholder"
local CURSOR_HTML_PATH = SCRIPT_DIR .. "screen-studio-lite/cursor-layer.html"
CAMERA_PLACEHOLDER_HTML_PATH = SCRIPT_DIR .. "screen-studio-lite/camera-placeholder.html"
CURSOR_HOTSPOT_X = 28
CURSOR_HOTSPOT_Y = 15
CURSOR_CLICK_HOTSPOT_X = 13
CURSOR_CLICK_HOTSPOT_Y = 56
local STUDIO_SCENE_NAME = "Screen Studio Recording"
local HOTKEY_ZOOM_IN = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_ZOOM_OUT = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_RESET = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_ROUND = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_ZOOM_CURSOR = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_START_RECORDING = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_STOP_RECORDING = obs.OBS_INVALID_HOTKEY_ID
local HOTKEY_MARK_CHAPTER = obs.OBS_INVALID_HOTKEY_ID
local ALIGN_TOP_LEFT = 5

local settings_state = {
	zoom_step = 1.18,
	zoom_duration_ms = 620,
	max_zoom = 3.0,
	min_zoom = 0.25,
	use_smooth_zoom = true,
	mask_type = 1,
	corner_preset = "large",
	create_background = true,
	card_width = 1728,
	card_height = 972,
	card_color = 0x1F232A,
	card_margin = 180,
	card_source_name = "Screen Studio Card",
	rectangle_source_name = "Rounded Rectangle",
	click_zoom_enabled = true,
	click_zoom_scale = 2.0,
	typing_zoom_scale = 2.6,
	click_reset_delay_ms = 5000,
	auto_focus_enabled = false,
	auto_focus_dwell_ms = 900,
	auto_focus_move_threshold = 18,
	auto_focus_cooldown_ms = 2400,
	text_focus_enabled = true,
	text_focus_cooldown_ms = 900,
	zoom_adds_chapter = true,
	click_area_mode = "primary",
	click_manual_x = 0,
	click_manual_y = 0,
	click_manual_width = 1920,
	click_manual_height = 1080,
	visual_layer_enabled = true,
	visual_layer_style = "aurora",
	visual_layer_card = true,
	visual_layer_cursor = true,
	visual_layer_cursor_scale = 1.35,
	visual_layer_idle_ms = 0,
	visual_layer_smoothing = 0.20,
	visual_layer_touch_cursor = false,
	visual_keystrokes = true,
	visual_keystroke_hold_ms = 1200,
	visual_keystroke_position = "bottom",
	visual_cursor_rotate = true,
	visual_cursor_shake_threshold = 1.2,
	visual_cursor_color = "#FFFFFF",
	visual_cursor_accent = "#2DD4BF",
	visual_click_color = "#FFFFFF",
	visual_card_inset = 8.5,
	visual_card_radius = 34,
	visual_card_opacity = 62,
	visual_shadow_strength = 34,
	visual_bg_solid = true,
	visual_bg_color_a = "#CBD198",
	visual_bg_color_b = "#CBD198",
	visual_bg_color_c = "#CBD198",
	visual_bg_image = "",
	visual_layer_source_name = VISUAL_LAYER_SOURCE_NAME,
	frame_layer_source_name = FRAME_LAYER_SOURCE_NAME,
	cursor_layer_source_name = CURSOR_LAYER_SOURCE_NAME,
	camera_enabled = false,
	camera_placeholder_source_name = CAMERA_PLACEHOLDER_SOURCE_NAME,
	zoom_target_source_name = "Screen Capture",
	capture_source_name = "Screen Capture",
	window_source_name = "Window Capture",
	area_source_name = "Area Capture",
	camera_source_name = "Camera",
	mic_source_name = "Microphone",
	system_audio_source_name = "System Audio",
	camera_position = "bottom-right",
	camera_size_pct = 22,
	camera_margin = 80,
	area_crop_left = 0,
	area_crop_top = 0,
	area_crop_right = 0,
	area_crop_bottom = 0,
	studio_profile_bitrate = 90000,
	studio_profile_path = "",
	studio_canvas_preset = "portrait_3_4",
	studio_canvas_width = 2160,
	studio_canvas_height = 2880,
	studio_recording_starts_watcher = true,
	studio_recording_adds_chapters = true,
	studio_auto_apply_4k_profile = true,
	studio_scene_name = STUDIO_SCENE_NAME,
	studio_use_dedicated_scene = false,
	studio_auto_setup_on_load = true,
	studio_auto_start_zoom_on_load = true,
	studio_exclude_taskbar = true,
}

local animations = {}
local saved_transforms = {}
local timeline_events = {}
local timeline_started_ms = 0
local click_zoom_running = false
local last_click_event = nil
local pending_click_reset = nil
local recording_was_active = false
local last_recording_path = ""
local dwell_anchor_x = nil
local dwell_anchor_y = nil
local dwell_started_at = 0
local last_auto_focus_time = 0
local last_auto_focus_x = nil
local last_auto_focus_y = nil
local last_click_zoom_time = 0
local smoothed_cursor_x = nil
local smoothed_cursor_y = nil
local last_cursor_time = 0
local last_cursor_event = 0
local cursor_click_state_active = false
local cursor_layer_url
local last_taskbar_crop_signature = ""
local last_dynamic_mask_signature = ""
local canvas_size
local preferred_canvas_size
local corner_radius_for_source_height
local fit_item_to_canvas_area
zoom_camera_active_until = zoom_camera_active_until or 0
last_raw_cursor_x = last_raw_cursor_x or nil
last_raw_cursor_y = last_raw_cursor_y or nil
last_pointer_activity_ms = last_pointer_activity_ms or 0
last_pointer_state_x = last_pointer_state_x or nil
last_pointer_state_y = last_pointer_state_y or nil

function clamp(value, min_value, max_value)
	if value < min_value then
		return min_value
	end
	if value > max_value then
		return max_value
	end
	return value
end

function ease_out_cubic(t)
	local p = 1.0 - t
	return 1.0 - (p * p * p * p)
end

function ease_smoother_step(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

function ease_reset_pullback(t)
	local eased = ease_smoother_step(t)
	local settle = math.sin(t * math.pi) * 0.025 * (1.0 - t)
	return clamp(eased + settle, 0.0, 1.0)
end

function ease_screen_studio_zoom(t)
	local c1 = 0.42
	local c3 = c1 + 1.0
	local p = t - 1.0
	return 1.0 + (c3 * p * p * p) + (c1 * p * p)
end

function make_vec2(x, y)
	local v = obs.vec2()
	v.x = x
	v.y = y
	return v
end

function quote_arg(value)
	return '"' .. tostring(value):gsub('"', '\\"') .. '"'
end

function ps_quote(value)
	return "'" .. tostring(value or ""):gsub("'", "''") .. "'"
end

function shell_quote(value)
	return '"' .. tostring(value or ""):gsub('"', '\\"') .. '"'
end

function color_source_hex_from_source(source)
	local settings = obs.obs_source_get_settings(source)
	local color = settings ~= nil and obs.obs_data_get_int(settings, "color") or 0
	if settings ~= nil then
		obs.obs_data_release(settings)
	end

	if color == nil or color == 0 then
		return nil
	end
	if color < 0 then
		color = color + 4294967296
	end

	local r = color % 256
	local g = math.floor(color / 256) % 256
	local b = math.floor(color / 65536) % 256
	return string.format("#%02X%02X%02X", r, g, b)
end

color_source_hex_by_name = function(source_name)
	local source = obs.obs_get_source_by_name(source_name)
	if source == nil then
		return nil
	end

	local color = color_source_hex_from_source(source)
	obs.obs_source_release(source)
	return color
end

function is_plain_color_source(source)
	if source == nil then
		return false
	end

	local source_id = ""
	local unversioned_id = ""
	if obs.obs_source_get_id ~= nil then
		source_id = obs.obs_source_get_id(source) or ""
	end
	if obs.obs_source_get_unversioned_id ~= nil then
		unversioned_id = obs.obs_source_get_unversioned_id(source) or ""
	end

	return string.find(source_id, "color_source", 1, true) ~= nil
		or string.find(unversioned_id, "color_source", 1, true) ~= nil
end

function solid_background_color()
	for _, name in ipairs({ "Color", "Colour", "Color Source" }) do
		local color = color_source_hex_by_name(name)
		if color ~= nil then
			return color
		end
	end

	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		local result = nil
		for _, source in ipairs(sources) do
			local name = obs.obs_source_get_name(source) or ""
			if is_plain_color_source(source)
				and name ~= settings_state.card_source_name
				and name ~= settings_state.rectangle_source_name then
				result = color_source_hex_from_source(source)
				if result ~= nil then
					break
				end
			end
		end
		obs.source_list_release(sources)
		if result ~= nil then
			return result
		end
	end

	return settings_state.visual_bg_color_a or "#CBD198"
end

function file_exists(path)
	local file = io.open(path, "r")
	if file == nil then
		return false
	end
	file:close()
	return true
end

function file_url(path)
	local normalized = tostring(path):gsub("\\", "/")
	normalized = normalized:gsub(" ", "%%20")
	return "file:///" .. normalized
end

function url_encode(value)
	local text = tostring(value or "")
	text = text:gsub("\n", "\r\n")
	return text:gsub("([^%w%-_%.~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end)
end

function wall_clock()
	return os.date("%Y-%m-%d %H:%M:%S")
end

function now_ms()
	return math.floor(obs.os_gettime_ns() / 1000000)
end

function recording_active()
	return obs.obs_frontend_recording_active ~= nil and obs.obs_frontend_recording_active()
end

function json_escape(value)
	local text = tostring(value or "")
	text = text:gsub("\\", "\\\\")
	text = text:gsub('"', '\\"')
	text = text:gsub("\r", "\\r")
	text = text:gsub("\n", "\\n")
	text = text:gsub("\t", "\\t")
	return text
end

function write_timeline_json()
	local file = io.open(TIMELINE_JSON_PATH, "w")
	if file == nil then
		return
	end

	file:write("{\n")
	file:write('  "version": 1,\n')
	file:write('  "scene": "' .. json_escape(settings_state.studio_scene_name) .. '",\n')
	file:write('  "events": [\n')
	for index, event in ipairs(timeline_events) do
		file:write("    {")
		file:write('"time": "' .. json_escape(event.time) .. '", ')
		file:write('"offsetMs": ' .. tostring(event.offset_ms or 0) .. ', ')
		file:write('"durationMs": ' .. tostring(event.duration_ms or 0) .. ', ')
		file:write('"type": "' .. json_escape(event.type) .. '", ')
		file:write('"details": "' .. json_escape(event.details) .. '"')
		if event.x ~= nil and event.y ~= nil then
			file:write(', "x": ' .. tostring(event.x) .. ', "y": ' .. tostring(event.y))
		end
		if event.zoom ~= nil then
			file:write(', "zoom": ' .. tostring(event.zoom))
		end
		file:write("}")
		if index < #timeline_events then
			file:write(",")
		end
		file:write("\n")
	end
	file:write("  ]\n")
	file:write("}\n")
	file:close()
end

function write_live_status(label, x, y, zoom, transform)
	local file = io.open(LIVE_STATUS_PATH, "w")
	if file == nil then
		return
	end

	file:write("{\n")
	file:write('  "updatedAt": "' .. json_escape(wall_clock()) .. '",\n')
	file:write('  "event": "' .. json_escape(label or "") .. '",\n')
	file:write('  "x": ' .. tostring(math.floor(x or 0)) .. ',\n')
	file:write('  "y": ' .. tostring(math.floor(y or 0)) .. ',\n')
	file:write('  "zoom": ' .. tostring(zoom or settings_state.click_zoom_scale) .. ',\n')
	file:write('  "resetDelayMs": ' .. tostring(settings_state.click_reset_delay_ms))
	if transform ~= nil then
		file:write(',\n')
		file:write('  "targetPos": { "x": ' .. tostring(transform.pos_x or 0) .. ', "y": ' .. tostring(transform.pos_y or 0) .. ' },\n')
		file:write('  "targetScale": { "x": ' .. tostring(transform.scale_x or 0) .. ', "y": ' .. tostring(transform.scale_y or 0) .. ' },\n')
		file:write('  "targetBounds": { "x": ' .. tostring(transform.bounds_x or 0) .. ', "y": ' .. tostring(transform.bounds_y or 0) .. ' },\n')
		file:write('  "boundsType": ' .. tostring(transform.bounds_type or 0) .. '\n')
	else
		file:write('\n')
	end
	file:write("}\n")
	file:close()
end

function set_cursor_click_source_state(active)
	local source = obs.obs_get_source_by_name(settings_state.cursor_layer_source_name)
	if source == nil then
		return
	end

	local settings = obs.obs_source_get_settings(source)
	if settings ~= nil then
		obs.obs_data_set_string(settings, "url", cursor_layer_url(active))
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
	end
	obs.obs_source_release(source)
end

function reset_cursor_click_source_state()
	obs.timer_remove(reset_cursor_click_source_state)
	cursor_click_state_active = false
	set_cursor_click_source_state(false)
end

function show_click_cursor_state()
	cursor_click_state_active = true
	set_cursor_click_source_state(true)
	obs.timer_remove(reset_cursor_click_source_state)
	obs.timer_add(reset_cursor_click_source_state, 720)
end

function ps_escape(value)
	return tostring(value or ""):gsub("'", "''")
end

function sanitize_dimension(value, fallback)
	local number = math.floor(tonumber(value) or fallback or 0)
	if number < 64 then
		return fallback or 1920
	end
	if number > 7680 then
		return 7680
	end
	return number
end

function studio_canvas_settings()
	local presets = {
		uhd_16_9 = { width = 3840, height = 2160, label = "16:9 UHD" },
		hd_16_9 = { width = 1920, height = 1080, label = "16:9 HD" },
		portrait_9_16 = { width = 2160, height = 3840, label = "9:16 Vertical" },
		portrait_3_4 = { width = 2160, height = 2880, label = "3:4 Portrait" },
		portrait_4_5 = { width = 2160, height = 2700, label = "4:5 Portrait" },
		square_1_1 = { width = 2160, height = 2160, label = "1:1 Square" },
		classic_4_3 = { width = 2880, height = 2160, label = "4:3 Classic" },
	}

	local preset_key = settings_state.studio_canvas_preset or "portrait_3_4"
	if preset_key == "custom" then
		local width = sanitize_dimension(settings_state.studio_canvas_width, 2160)
		local height = sanitize_dimension(settings_state.studio_canvas_height, 2880)
		return width, height, tostring(width) .. "x" .. tostring(height) .. " Custom"
	end

	local preset = presets[preset_key] or presets.portrait_3_4
	return preset.width, preset.height, preset.label
end

function studio_export_suffix(width, height)
	return "screenstudio-" .. tostring(width) .. "x" .. tostring(height)
end

function write_export_script(recording_path)
	local file = io.open(STUDIO_EXPORT_SCRIPT_PATH, "w")
	if file == nil then
		return
	end

	local export_width, export_height, export_label = studio_canvas_settings()
	local suffix = studio_export_suffix(export_width, export_height)
	local input_path = tostring(recording_path or "")
	local output_path = input_path
	if output_path ~= "" then
		output_path = output_path:gsub("(%.[^%.\\/]*)$", "-" .. suffix .. ".mp4")
		if output_path == input_path then
			output_path = input_path .. "-" .. suffix .. ".mp4"
		end
	else
		output_path = (os.getenv("USERPROFILE") or "") .. "\\Videos\\" .. suffix .. "-export.mp4"
	end

	file:write("$ErrorActionPreference = 'Stop'\n")
	file:write("$inputPath = '" .. ps_escape(input_path) .. "'\n")
	file:write("$outputPath = '" .. ps_escape(output_path) .. "'\n")
	file:write("$exportWidth = " .. tostring(export_width) .. "\n")
	file:write("$exportHeight = " .. tostring(export_height) .. "\n")
	file:write("if ([string]::IsNullOrWhiteSpace($inputPath) -or -not (Test-Path -LiteralPath $inputPath)) {\n")
	file:write("  throw 'Recording file not found. Finish one Studio Recording first, then reopen the editor.'\n")
	file:write("}\n")
	file:write("$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue\n")
	file:write("if (-not $ffmpeg) {\n")
	file:write("  Copy-Item -LiteralPath $inputPath -Destination $outputPath -Force\n")
	file:write("  Write-Host \"ffmpeg was not found on PATH; copied the existing OBS recording to $outputPath\"\n")
	file:write("  return\n")
	file:write("}\n")
	file:write("& $ffmpeg.Source -y -i $inputPath -vf \"scale=${exportWidth}:${exportHeight}:force_original_aspect_ratio=decrease,pad=${exportWidth}:${exportHeight}:(ow-iw)/2:(oh-ih)/2,format=yuv420p\" -c:v libx264 -preset slow -crf 16 -c:a aac -b:a 320k -movflags +faststart $outputPath\n")
	file:write("Write-Host \"Exported $outputPath\"\n")
	file:close()

	local launcher = io.open(STUDIO_EXPORT_CMD_PATH, "w")
	if launcher ~= nil then
		launcher:write("@echo off\n")
		launcher:write("setlocal\n")
		launcher:write("powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%~dp0export-video.ps1\"\n")
		launcher:write("pause\n")
		launcher:close()
	end
end

function read_project_recording_path()
	local file = io.open(STUDIO_PROJECT_PATH, "r")
	if file == nil then
		return ""
	end

	local text = file:read("*a") or ""
	file:close()

	local value = text:match('"recordingPath"%s*:%s*"(.-)"') or ""
	value = value:gsub("\\/", "/")
	value = value:gsub('\\"', '"')
	value = value:gsub("\\\\", "\\")
	return value
end

function write_studio_project(recording_path, preserve_existing)
	local resolved_recording_path = tostring(recording_path or "")
	if resolved_recording_path == "" and preserve_existing ~= false then
		resolved_recording_path = read_project_recording_path()
	end
	last_recording_path = resolved_recording_path

	local file = io.open(STUDIO_PROJECT_PATH, "w")
	if file == nil then
		return
	end

	local export_width, export_height, export_label = studio_canvas_settings()
	file:write("{\n")
	file:write('  "version": 1,\n')
	file:write('  "updatedAt": "' .. json_escape(wall_clock()) .. '",\n')
	file:write('  "scene": "' .. json_escape(settings_state.studio_scene_name) .. '",\n')
	file:write('  "recordingPath": "' .. json_escape(resolved_recording_path) .. '",\n')
	file:write('  "timelinePath": "' .. json_escape(TIMELINE_JSON_PATH) .. '",\n')
	file:write('  "exportScriptPath": "' .. json_escape(STUDIO_EXPORT_SCRIPT_PATH) .. '",\n')
	file:write('  "exportLauncherPath": "' .. json_escape(STUDIO_EXPORT_CMD_PATH) .. '",\n')
	file:write('  "export": {\n')
	file:write('    "width": ' .. tostring(export_width) .. ',\n')
	file:write('    "height": ' .. tostring(export_height) .. ',\n')
	file:write('    "label": "' .. json_escape(export_label) .. '",\n')
	file:write('    "aspectRatio": "' .. json_escape(tostring(export_width) .. ":" .. tostring(export_height)) .. '",\n')
	file:write('    "fps": 60,\n')
	file:write('    "bitrateKbps": ' .. tostring(settings_state.studio_profile_bitrate) .. ',\n')
	file:write('    "format": "mp4"\n')
	file:write("  },\n")
	file:write('  "events": [\n')
	for index, event in ipairs(timeline_events) do
		file:write("    {")
		file:write('"time": "' .. json_escape(event.time) .. '", ')
		file:write('"offsetMs": ' .. tostring(event.offset_ms or 0) .. ', ')
		file:write('"durationMs": ' .. tostring(event.duration_ms or 0) .. ', ')
		file:write('"type": "' .. json_escape(event.type) .. '", ')
		file:write('"details": "' .. json_escape(event.details) .. '"')
		if event.x ~= nil and event.y ~= nil then
			file:write(', "x": ' .. tostring(event.x) .. ', "y": ' .. tostring(event.y))
		end
		if event.zoom ~= nil then
			file:write(', "zoom": ' .. tostring(event.zoom))
		end
		file:write("}")
		if index < #timeline_events then
			file:write(",")
		end
		file:write("\n")
	end
	file:write("  ]\n")
	file:write("}\n")
	file:close()
	write_export_script(resolved_recording_path)
end

function append_timeline(event_name, details, x, y, zoom)
	local elapsed_ms = 0
	if timeline_started_ms > 0 then
		elapsed_ms = math.max(0, now_ms() - timeline_started_ms)
	end

	local event = {
		time = wall_clock(),
		offset_ms = elapsed_ms,
		duration_ms = settings_state.zoom_duration_ms,
		type = tostring(event_name),
		details = tostring(details or ""),
		x = x,
		y = y,
		zoom = zoom,
	}
	table.insert(timeline_events, event)

	local file = io.open(TIMELINE_PATH, "a")
	if file == nil then
		write_timeline_json()
		return
	end

	file:write("- " .. event.time .. " | " .. event.type)
	if details ~= nil and details ~= "" then
		file:write(" | " .. event.details)
	end
	if x ~= nil and y ~= nil then
		file:write(" | x=" .. tostring(x) .. ", y=" .. tostring(y))
	end
	file:write("\n")
	file:close()
	write_timeline_json()
	write_studio_project(last_recording_path)
end

function reset_timeline()
	timeline_events = {}
	timeline_started_ms = now_ms()
	last_recording_path = ""
	local file = io.open(TIMELINE_PATH, "w")
	if file == nil then
		write_timeline_json()
		write_studio_project("", false)
		return
	end

	file:write("# Screen Studio Lite Timeline\n\n")
	file:write("Started: " .. wall_clock() .. "\n\n")
	file:close()
	write_timeline_json()
	write_studio_project("", false)
end

function visual_layer_url(mode)
	local canvas_width, canvas_height = preferred_canvas_size()
	local frame_radius = corner_radius_for_source_height(canvas_height)
	local solid_color = solid_background_color()
	local query = "?state=" .. url_encode(CLICK_STATE_URL) ..
		"&mode=" .. url_encode(mode or "background") ..
		"&style=" .. url_encode(settings_state.visual_layer_style) ..
		"&cursor=" .. tostring(settings_state.visual_layer_cursor and 1 or 0) ..
		"&card=" .. tostring(settings_state.visual_layer_card and 1 or 0) ..
		"&touch=" .. tostring(settings_state.visual_layer_touch_cursor and 1 or 0) ..
		"&keys=" .. tostring(settings_state.visual_keystrokes and 1 or 0) ..
		"&keyHold=" .. tostring(settings_state.visual_keystroke_hold_ms) ..
		"&keyPosition=" .. url_encode(settings_state.visual_keystroke_position) ..
		"&rotate=" .. tostring(settings_state.visual_cursor_rotate and 1 or 0) ..
		"&scale=" .. tostring(settings_state.visual_layer_cursor_scale) ..
		"&idle=" .. tostring(settings_state.visual_layer_idle_ms) ..
		"&smooth=" .. tostring(settings_state.visual_layer_smoothing) ..
		"&shake=" .. tostring(settings_state.visual_cursor_shake_threshold) ..
		"&cursorColor=" .. url_encode(settings_state.visual_cursor_color) ..
		"&accent=" .. url_encode(settings_state.visual_cursor_accent) ..
		"&clickColor=" .. url_encode(settings_state.visual_click_color) ..
		"&cardInset=" .. tostring(settings_state.visual_card_inset) ..
		"&cardRadius=" .. tostring(settings_state.visual_card_radius) ..
		"&cardOpacity=" .. tostring(settings_state.visual_card_opacity) ..
		"&shadow=" .. tostring(settings_state.visual_shadow_strength) ..
		"&frameMargin=" .. tostring(settings_state.card_margin) ..
		"&frameRadius=" .. tostring(frame_radius) ..
		"&frameScreen=1" ..
		"&resetDelay=" .. tostring(settings_state.click_reset_delay_ms) ..
		"&excludeTaskbar=" .. tostring(settings_state.studio_exclude_taskbar and 1 or 0) ..
		"&cameraCutout=" .. tostring(settings_state.camera_enabled and 1 or 0) ..
		"&cameraPosition=" .. url_encode(settings_state.camera_position) ..
		"&cameraSizePct=" .. tostring(settings_state.camera_size_pct) ..
		"&cameraMargin=" .. tostring(settings_state.camera_margin) ..
		"&solidBg=" .. tostring(settings_state.visual_bg_solid and 1 or 0) ..
		"&bgA=" .. url_encode(solid_color) ..
		"&bgB=" .. url_encode(solid_color) ..
		"&bgC=" .. url_encode(solid_color) ..
		"&bgImage=" .. url_encode(settings_state.visual_bg_image)

	return file_url(VISUAL_LAYER_PATH) .. query
end

cursor_layer_url = function(click_state)
	local query = "?state=" .. url_encode(click_state and "click" or "idle") ..
		"&v=" .. tostring(now_ms())
	return file_url(CURSOR_HTML_PATH) .. query
end

function current_mask_path()
	if settings_state.corner_preset == "small" then
		return MASK_DIR .. "rounded-small-1920x1080.png"
	end

	if settings_state.corner_preset == "large" then
		return MASK_DIR .. "rounded-large-1920x1080.png"
	end

	return MASK_DIR .. "rounded-medium-1920x1080.png"
end

corner_radius_for_source_height = function(source_height)
	local height = math.max(1, source_height or 1080)
	local base_radius = 34
	if settings_state.corner_preset == "small" then
		base_radius = 22
	elseif settings_state.corner_preset == "large" then
		base_radius = 54
	end
	return math.max(8, math.floor(base_radius * (height / 1080) + 0.5))
end

local ensure_studio_scene

function can_use_dedicated_live_scene()
	return settings_state.studio_use_dedicated_scene and obs.obs_frontend_set_current_scene ~= nil
end

function scene_source_from_frontend()
	if can_use_dedicated_live_scene() then
		local studio_scene, studio_source = ensure_studio_scene()
		if studio_scene ~= nil then
			return studio_scene, studio_source
		end
		if studio_source ~= nil then
			obs.obs_source_release(studio_source)
		end
	end

	local source = nil
	if obs.obs_frontend_get_current_scene ~= nil then
		source = obs.obs_frontend_get_current_scene()
	elseif obs.obs_frontend_get_current_preview_scene ~= nil then
		source = obs.obs_frontend_get_current_preview_scene()
	end

	if source == nil then
		return nil, nil
	end

	local scene = obs.obs_scene_from_source(source)
	return scene, source
end

ensure_studio_scene = function()
	local scene_name = settings_state.studio_scene_name
	if scene_name == nil or scene_name == "" then
		scene_name = STUDIO_SCENE_NAME
	end

	local source = obs.obs_get_source_by_name(scene_name)
	if source ~= nil then
		local scene = obs.obs_scene_from_source(source)
		return scene, source
	end

	local scene = obs.obs_scene_create(scene_name)
	if scene == nil then
		print("[Screen Studio Lite] Could not create Studio scene.")
		return nil, nil
	end

	source = obs.obs_scene_get_source(scene)
	if source ~= nil then
		source = obs.obs_source_get_ref(source)
	end

	return scene, source
end

function use_studio_scene_if_enabled()
	if not settings_state.studio_use_dedicated_scene then
		return
	end

	if obs.obs_frontend_set_current_scene == nil then
		print("[Screen Studio Lite] OBS scripting cannot switch the live scene in this build. Building the Studio setup in the current scene so click zoom is visible.")
		return
	end

	local scene, source = ensure_studio_scene()
	if scene == nil then
		if source ~= nil then
			obs.obs_source_release(source)
		end
		return
	end

	obs.obs_frontend_set_current_scene(source)
	print("[Screen Studio Lite] Switched to Studio scene: " .. settings_state.studio_scene_name)

	if source ~= nil then
		obs.obs_source_release(source)
	end
end

function release_source(source)
	if source ~= nil then
		obs.obs_source_release(source)
	end
end

function set_frame_layer_visible(visible)
	local scene, scene_source = scene_source_from_frontend()
	if scene ~= nil then
		local item = obs.obs_scene_find_source(scene, settings_state.frame_layer_source_name)
		if item ~= nil then
			obs.obs_sceneitem_set_visible(item, visible)
			print("[Screen Studio Lite] Frame layer " .. (visible and "shown for fullscreen rounded state." or "hidden for zoomed state."))
		end
	end
	release_source(scene_source)
end

function restore_frame_layer_tick()
	obs.timer_remove(restore_frame_layer_tick)
	zoom_camera_active_until = 0
	apply_fullscreen_round_mask()
	set_frame_layer_visible(true)
end

canvas_size = function()
	local video_info = obs.obs_video_info()
	if obs.obs_get_video_info(video_info) then
		return video_info.base_width, video_info.base_height
	end

	return 1920, 1080
end

preferred_canvas_size = function()
	if settings_state.studio_auto_apply_4k_profile then
		local width, height = studio_canvas_settings()
		return width, height
	end

	return canvas_size()
end

function find_selected_scene_item()
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		if scene_source ~= nil then
			obs.obs_source_release(scene_source)
		end
		return nil, nil
	end

	local selected_item = nil
	obs.obs_scene_enum_items(scene, function(_, item)
		if obs.obs_sceneitem_selected(item) then
			selected_item = item
			obs.obs_sceneitem_addref(selected_item)
			return false
		end

		return true
	end, nil)

	obs.obs_source_release(scene_source)
	return selected_item, scene
end

function find_scene_item_by_source_names(names)
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		release_source(scene_source)
		return nil
	end

	local lookup = {}
	for _, name in ipairs(names) do
		if name ~= nil and name ~= "" then
			lookup[name] = true
			local direct_item = nil
			if obs.obs_scene_find_source_recursive ~= nil then
				direct_item = obs.obs_scene_find_source_recursive(scene, name)
			end
			if direct_item == nil then
				direct_item = obs.obs_scene_find_source(scene, name)
			end
			if direct_item ~= nil then
				obs.obs_sceneitem_addref(direct_item)
				release_source(scene_source)
				return direct_item
			end
		end
	end

	local found_item = nil
	obs.obs_scene_enum_items(scene, function(_, item)
		local source = obs.obs_sceneitem_get_source(item)
		local name = source ~= nil and obs.obs_source_get_name(source) or nil
		if name ~= nil and lookup[name] then
			found_item = item
			obs.obs_sceneitem_addref(found_item)
			return false
		end

		return true
	end, nil)

	release_source(scene_source)
	return found_item
end

function source_matches_id_set(source, source_ids)
	if source == nil or source_ids == nil or obs.obs_source_get_id == nil then
		return false
	end

	local source_id = obs.obs_source_get_id(source)
	if source_id ~= nil and source_ids[source_id] == true then
		return true
	end

	if obs.obs_source_get_unversioned_id ~= nil then
		source_id = obs.obs_source_get_unversioned_id(source)
		return source_id ~= nil and source_ids[source_id] == true
	end

	return false
end

function find_scene_item_by_source_ids(source_ids)
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		release_source(scene_source)
		return nil
	end

	local found_item = nil
	obs.obs_scene_enum_items(scene, function(_, item)
		local source = obs.obs_sceneitem_get_source(item)
		local name = source ~= nil and obs.obs_source_get_name(source) or ""
		if source_matches_id_set(source, source_ids)
			and name ~= settings_state.visual_layer_source_name
			and name ~= settings_state.frame_layer_source_name
			and name ~= settings_state.cursor_layer_source_name then
			found_item = item
			obs.obs_sceneitem_addref(found_item)
			return false
		end

		return true
	end, nil)

	release_source(scene_source)
	return found_item
end

function find_scene_item_by_source_name_anywhere(source_name)
	if source_name == nil or source_name == "" then
		return nil
	end

	local scene_source = obs.obs_get_source_by_name(settings_state.studio_scene_name or STUDIO_SCENE_NAME)
	if scene_source == nil then
		return nil
	end

	local scene = obs.obs_scene_from_source(scene_source)
	if scene == nil then
		obs.obs_source_release(scene_source)
		return nil
	end

	local item = obs.obs_scene_find_source(scene, source_name)
	if item ~= nil then
		obs.obs_sceneitem_addref(item)
	end

	obs.obs_source_release(scene_source)
	return item
end

function find_zoom_target_scene_item(quiet)
	local item = nil
	if settings_state.zoom_target_source_name ~= nil and settings_state.zoom_target_source_name ~= "" then
		item = find_scene_item_by_source_names({ settings_state.zoom_target_source_name })
		if item ~= nil then
			if not quiet then
				print("[Screen Studio Lite] Auto Zoom target found by name: " .. settings_state.zoom_target_source_name)
			end
			return item
		end
	end

	item = find_scene_item_by_source_names({
		settings_state.capture_source_name,
		settings_state.window_source_name,
		settings_state.area_source_name,
	})

	if item ~= nil then
		if not quiet then
			print("[Screen Studio Lite] Auto Zoom target found by configured capture source.")
		end
		return item
	end

	item = find_scene_item_by_source_ids({
		monitor_capture = true,
		window_capture = true,
		game_capture = true,
	})

	if item ~= nil then
		if not quiet then
			print("[Screen Studio Lite] Auto Zoom target found by source type.")
		end
		return item
	end

	if settings_state.zoom_target_source_name ~= nil and settings_state.zoom_target_source_name ~= "" then
		item = find_scene_item_by_source_name_anywhere(settings_state.zoom_target_source_name)
		if item ~= nil then
			return item
		end
	end

	item = find_selected_scene_item()
	if item ~= nil then
		if not quiet then
			print("[Screen Studio Lite] Auto Zoom using selected source as fallback.")
		end
		return item
	end

	if not quiet then
		print("[Screen Studio Lite] Auto Zoom needs a selected screen/window/area source.")
	end
	return nil
end

function select_only_scene_item(target_item)
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		release_source(scene_source)
		return
	end

	obs.obs_scene_enum_items(scene, function(_, item)
		obs.obs_sceneitem_select(item, item == target_item)
		return true
	end, nil)

	release_source(scene_source)
end

function release_item(item)
	if item ~= nil then
		obs.obs_sceneitem_release(item)
	end
end

function remove_round_mask_for_scene_item(item)
	if item == nil then
		return
	end

	local source = obs.obs_sceneitem_get_source(item)
	if source == nil then
		return
	end

	local filter = obs.obs_source_get_filter_by_name(source, FILTER_NAME)
	if filter ~= nil then
		obs.obs_source_filter_remove(source, filter)
		obs.obs_source_release(filter)
	end
end

function save_original_transform(item)
	if item == nil then
		return
	end

	local id = tostring(obs.obs_sceneitem_get_id(item))
	if saved_transforms[id] ~= nil then
		return
	end

	local pos = obs.vec2()
	local scale = obs.vec2()
	local bounds = obs.vec2()
	obs.obs_sceneitem_get_pos(item, pos)
	obs.obs_sceneitem_get_scale(item, scale)
	obs.obs_sceneitem_get_bounds(item, bounds)

	saved_transforms[id] = {
		pos_x = pos.x,
		pos_y = pos.y,
		scale_x = scale.x,
		scale_y = scale.y,
		rot = obs.obs_sceneitem_get_rot(item),
		alignment = obs.obs_sceneitem_get_alignment(item),
		bounds_type = obs.obs_sceneitem_get_bounds_type(item),
		bounds_alignment = obs.obs_sceneitem_get_bounds_alignment(item),
		bounds_x = bounds.x,
		bounds_y = bounds.y,
		crop_to_bounds = obs.obs_sceneitem_get_bounds_crop(item),
	}
end

function set_transform(item, transform)
	if item == nil or transform == nil then
		return
	end

	local info = obs.obs_transform_info()
	info.pos = make_vec2(transform.pos_x, transform.pos_y)
	info.rot = transform.rot
	info.scale = make_vec2(transform.scale_x, transform.scale_y)
	info.alignment = transform.alignment
	info.bounds_type = transform.bounds_type
	info.bounds_alignment = transform.bounds_alignment
	info.bounds = make_vec2(transform.bounds_x, transform.bounds_y)
	info.crop_to_bounds = transform.crop_to_bounds

	obs.obs_sceneitem_defer_update_begin(item)
	obs.obs_sceneitem_set_info2(item, info)
	obs.obs_sceneitem_defer_update_end(item)
	obs.obs_sceneitem_force_update_transform(item)
end

function current_transform(item)
	if item == nil then
		return nil
	end

	local pos = obs.vec2()
	local scale = obs.vec2()
	local bounds = obs.vec2()
	obs.obs_sceneitem_get_pos(item, pos)
	obs.obs_sceneitem_get_scale(item, scale)
	obs.obs_sceneitem_get_bounds(item, bounds)

	return {
		pos_x = pos.x,
		pos_y = pos.y,
		scale_x = scale.x,
		scale_y = scale.y,
		rot = obs.obs_sceneitem_get_rot(item),
		alignment = obs.obs_sceneitem_get_alignment(item),
		bounds_type = obs.obs_sceneitem_get_bounds_type(item),
		bounds_alignment = obs.obs_sceneitem_get_bounds_alignment(item),
		bounds_x = bounds.x,
		bounds_y = bounds.y,
		crop_to_bounds = obs.obs_sceneitem_get_bounds_crop(item),
	}
end

function item_size(item)
	local source = obs.obs_sceneitem_get_source(item)
	if source == nil then
		return 0, 0
	end

	local width = obs.obs_source_get_width(source)
	local height = obs.obs_source_get_height(source)
	return width, height
end

function scene_item_crop_values(item)
	local crop = obs.obs_sceneitem_crop()
	if obs.obs_sceneitem_get_crop ~= nil then
		obs.obs_sceneitem_get_crop(item, crop)
	end

	return crop.left or 0, crop.top or 0, crop.right or 0, crop.bottom or 0
end

function item_source_matches(item, source_ids)
	if item == nil then
		return false
	end

	local source = obs.obs_sceneitem_get_source(item)
	return source_matches_id_set(source, source_ids)
end

function center_of_item(item, transform)
	local width, height = item_size(item)
	local scale_x = transform.scale_x
	local scale_y = transform.scale_y

	if transform.bounds_type ~= obs.OBS_BOUNDS_NONE and transform.bounds_x > 0 and transform.bounds_y > 0 then
		width = transform.bounds_x
		height = transform.bounds_y
	end

	if width <= 0 or height <= 0 then
		return transform.pos_x, transform.pos_y
	end

	return transform.pos_x + (width * scale_x * 0.5), transform.pos_y + (height * scale_y * 0.5)
end

function base_scale_for_item(item, transform)
	local width, height = item_size(item)
	if width <= 0 or height <= 0 then
		return math.max(math.abs(transform.scale_x), math.abs(transform.scale_y), 1.0)
	end

	if transform.bounds_type ~= obs.OBS_BOUNDS_NONE and transform.bounds_x > 0 and transform.bounds_y > 0 then
		if transform.bounds_type == obs.OBS_BOUNDS_SCALE_OUTER then
			return math.max(transform.bounds_x / width, transform.bounds_y / height)
		end
		if transform.bounds_type == obs.OBS_BOUNDS_SCALE_TO_WIDTH then
			return transform.bounds_x / width
		end
		if transform.bounds_type == obs.OBS_BOUNDS_SCALE_TO_HEIGHT then
			return transform.bounds_y / height
		end

		return math.min(transform.bounds_x / width, transform.bounds_y / height)
	end

	return math.max(math.abs(transform.scale_x), math.abs(transform.scale_y), 1.0)
end

function enqueue_animation(item, target, duration_override_ms, easing)
	if item == nil or target == nil then
		return
	end

	local id = tostring(obs.obs_sceneitem_get_id(item))
	local duration = settings_state.use_smooth_zoom and (duration_override_ms or settings_state.zoom_duration_ms) or 0

	if duration <= 0 then
		set_transform(item, target)
		return
	end

	local start = current_transform(item)
	if start == nil then
		return
	end

	if animations[id] ~= nil then
		obs.obs_sceneitem_release(animations[id].item)
	end

	obs.obs_sceneitem_addref(item)
	animations[id] = {
		item = item,
		start = start,
		target = target,
		start_ns = obs.os_gettime_ns(),
		duration_ns = duration * 1000000,
		easing = easing or "smooth",
	}

	obs.timer_remove(animation_tick)
	obs.timer_add(animation_tick, 16)
end

function schedule_click_reset(item, zoom_duration_ms)
	if settings_state.click_reset_delay_ms <= 0 or item == nil then
		return
	end

	if pending_click_reset ~= nil and pending_click_reset.item ~= nil then
		obs.obs_sceneitem_release(pending_click_reset.item)
	end

	obs.obs_sceneitem_addref(item)
	local hold_ms = math.max(0, settings_state.click_reset_delay_ms or 0)
	local zoom_ms = math.max(0, zoom_duration_ms or settings_state.zoom_duration_ms or 0)
	local ready_ms = now_ms() + zoom_ms
	pending_click_reset = {
		item = item,
		earliest_ns = obs.os_gettime_ns() + (zoom_ms * 1000000),
		idle_ready_ms = ready_ms,
		idle_ms = hold_ms,
		last_activity_ms = math.max(last_pointer_activity_ms or 0, ready_ms),
	}

	obs.timer_remove(click_reset_tick)
	obs.timer_add(click_reset_tick, 50)
end

function click_reset_tick()
	if pending_click_reset == nil then
		obs.timer_remove(click_reset_tick)
		return
	end

	if obs.os_gettime_ns() < pending_click_reset.earliest_ns then
		return
	end

	local idle_ms = math.max(0, pending_click_reset.idle_ms or settings_state.click_reset_delay_ms or 0)
	local last_activity_ms = math.max(
		last_pointer_activity_ms or 0,
		pending_click_reset.last_activity_ms or 0,
		pending_click_reset.idle_ready_ms or 0
	)
	if idle_ms > 0 and last_activity_ms > 0 and (now_ms() - last_activity_ms) < idle_ms then
		zoom_camera_active_until = now_ms() + 250
		return
	end

	local item = pending_click_reset.item
	pending_click_reset = nil

	if item ~= nil then
		local id = tostring(obs.obs_sceneitem_get_id(item))
		local original = saved_transforms[id]
		if original ~= nil then
			local reset_duration = math.max(settings_state.zoom_duration_ms or 0, 900)
			enqueue_animation(item, original, reset_duration, "reset")
			write_live_status("Idle Reset", last_pointer_state_x or 0, last_pointer_state_y or 0, 1.0, original)
			print("[Screen Studio Lite] Idle Reset after " .. tostring(idle_ms) .. " ms without pointer movement.")
			obs.timer_remove(restore_frame_layer_tick)
			obs.timer_add(restore_frame_layer_tick, math.max(520, math.floor(reset_duration * 0.72)))
		else
			set_frame_layer_visible(true)
		end
		obs.obs_sceneitem_release(item)
	end

	obs.timer_remove(click_reset_tick)
end

function animation_tick()
	local now = obs.os_gettime_ns()
	local has_animation = false

	for id, anim in pairs(animations) do
		local progress = clamp((now - anim.start_ns) / anim.duration_ns, 0.0, 1.0)
		local eased = nil
		if anim.easing == "screen-studio" then
			eased = ease_screen_studio_zoom(progress)
		elseif anim.easing == "reset" then
			eased = ease_reset_pullback(progress)
		else
			eased = ease_out_cubic(progress)
		end
		local target = anim.target
		local start = anim.start

		local frame = {
			pos_x = start.pos_x + ((target.pos_x - start.pos_x) * eased),
			pos_y = start.pos_y + ((target.pos_y - start.pos_y) * eased),
			scale_x = start.scale_x + ((target.scale_x - start.scale_x) * eased),
			scale_y = start.scale_y + ((target.scale_y - start.scale_y) * eased),
			rot = start.rot + ((target.rot - start.rot) * eased),
			alignment = target.alignment,
			bounds_type = target.bounds_type,
			bounds_alignment = target.bounds_alignment,
			bounds_x = start.bounds_x + ((target.bounds_x - start.bounds_x) * eased),
			bounds_y = start.bounds_y + ((target.bounds_y - start.bounds_y) * eased),
			crop_to_bounds = target.crop_to_bounds,
		}

		set_transform(anim.item, frame)

		if progress >= 1.0 then
			obs.obs_sceneitem_release(anim.item)
			animations[id] = nil
		else
			has_animation = true
		end
	end

	if not has_animation then
		obs.timer_remove(animation_tick)
	end
end

function zoom_selected(multiplier)
	local item = nil
	item = find_zoom_target_scene_item()
	if item == nil then
		return
	end

	save_original_transform(item)
	local t = current_transform(item)
	if t == nil then
		release_item(item)
		return
	end

	local center_x, center_y = center_of_item(item, t)
	local current_zoom = math.max(math.abs(t.scale_x), math.abs(t.scale_y))
	local target_zoom = clamp(current_zoom * multiplier, settings_state.min_zoom, settings_state.max_zoom)
	local ratio = target_zoom / current_zoom
	local target = nil
	if t.bounds_type ~= obs.OBS_BOUNDS_NONE and t.bounds_x > 0 and t.bounds_y > 0 then
		local target_bounds_x = t.bounds_x * multiplier
		local target_bounds_y = t.bounds_y * multiplier
		target = {
			pos_x = center_x - ((center_x - t.pos_x) * multiplier),
			pos_y = center_y - ((center_y - t.pos_y) * multiplier),
			scale_x = t.scale_x,
			scale_y = t.scale_y,
			rot = t.rot,
			alignment = t.alignment,
			bounds_type = t.bounds_type,
			bounds_alignment = t.bounds_alignment,
			bounds_x = target_bounds_x,
			bounds_y = target_bounds_y,
			crop_to_bounds = t.crop_to_bounds,
		}
	else
		target = {
			pos_x = center_x - ((center_x - t.pos_x) * ratio),
			pos_y = center_y - ((center_y - t.pos_y) * ratio),
			scale_x = t.scale_x * ratio,
			scale_y = t.scale_y * ratio,
			rot = t.rot,
			alignment = t.alignment,
			bounds_type = t.bounds_type,
			bounds_alignment = t.bounds_alignment,
			bounds_x = t.bounds_x,
			bounds_y = t.bounds_y,
			crop_to_bounds = t.crop_to_bounds,
		}
	end

	obs.timer_remove(restore_frame_layer_tick)
	set_frame_layer_visible(false)
	enqueue_animation(item, target)
	release_item(item)
end

function reset_selected()
	local item = nil
	item = find_zoom_target_scene_item()
	if item == nil then
		return
	end

	local id = tostring(obs.obs_sceneitem_get_id(item))
	local original = saved_transforms[id]

	if original ~= nil then
		local reset_duration = math.max(settings_state.zoom_duration_ms or 0, 900)
		enqueue_animation(item, original, reset_duration, "reset")
		obs.timer_remove(restore_frame_layer_tick)
		obs.timer_add(restore_frame_layer_tick, math.max(520, math.floor(reset_duration * 0.72)))
	else
		local current = current_transform(item)
		if current ~= nil then
			current.pos_x = 0
			current.pos_y = 0
			current.scale_x = 1
			current.scale_y = 1
			current.bounds_type = obs.OBS_BOUNDS_NONE
			current.bounds_x = 0
			current.bounds_y = 0
			current.crop_to_bounds = false
			local reset_duration = math.max(settings_state.zoom_duration_ms or 0, 900)
			enqueue_animation(item, current, reset_duration, "reset")
			obs.timer_remove(restore_frame_layer_tick)
			obs.timer_add(restore_frame_layer_tick, math.max(520, math.floor(reset_duration * 0.72)))
		end
	end

	release_item(item)
end

function base_free_scale_for_zoom(base, source_width, source_height)
	local visible_width = math.max(1, source_width or 1)
	local visible_height = math.max(1, source_height or 1)
	local scale = math.max(math.abs(base.scale_x or 1), math.abs(base.scale_y or 1), 0.0001)

	if base.bounds_type ~= obs.OBS_BOUNDS_NONE and base.bounds_x > 0 and base.bounds_y > 0 then
		scale = math.min(base.bounds_x / visible_width, base.bounds_y / visible_height)
		if base.bounds_type == obs.OBS_BOUNDS_SCALE_OUTER then
			scale = math.max(base.bounds_x / visible_width, base.bounds_y / visible_height)
		elseif base.bounds_type == obs.OBS_BOUNDS_SCALE_TO_WIDTH then
			scale = base.bounds_x / visible_width
		elseif base.bounds_type == obs.OBS_BOUNDS_SCALE_TO_HEIGHT then
			scale = base.bounds_y / visible_height
		end
	end

	return math.max(scale, 0.0001)
end

function clamp_zoom_axis(pos, scaled_size, canvas_size)
	if scaled_size <= canvas_size then
		return clamp(pos, 0, canvas_size - scaled_size)
	end
	return clamp(pos, canvas_size - scaled_size, 0)
end

function zoom_transform_for_source_point(base, source_x, source_y, source_width, source_height, base_free_scale, zoom_override)
	local canvas_width, canvas_height = preferred_canvas_size()
	local zoom = clamp(zoom_override or settings_state.click_zoom_scale, 1.0, settings_state.max_zoom)
	local free_scale = base_free_scale or base_free_scale_for_zoom(base, source_width, source_height)
	local target_scale = free_scale * zoom
	local scaled_width = math.max(1, source_width or 1) * target_scale
	local scaled_height = math.max(1, source_height or 1) * target_scale
	local focus_x = canvas_width * 0.5
	local focus_y = canvas_height * 0.5
	local pos_x = focus_x - (source_x * target_scale)
	local pos_y = focus_y - (source_y * target_scale)

	pos_x = clamp_zoom_axis(pos_x, scaled_width, canvas_width)
	pos_y = clamp_zoom_axis(pos_y, scaled_height, canvas_height)

	return {
		pos_x = pos_x,
		pos_y = pos_y,
		scale_x = target_scale,
		scale_y = target_scale,
		rot = base.rot,
		alignment = ALIGN_TOP_LEFT,
		bounds_type = obs.OBS_BOUNDS_NONE,
		bounds_alignment = base.bounds_alignment,
		bounds_x = 0,
		bounds_y = 0,
		crop_to_bounds = false,
	}
end

function zoom_selected_to_source_point(source_x, source_y, fallback_width, fallback_height, zoom_override)
	local item = nil
	item = find_zoom_target_scene_item()
	if item == nil then
		return
	end

	save_original_transform(item)

	local current = current_transform(item)
	local source_width, source_height = item_size(item)
	if fallback_width ~= nil and fallback_width > 0 and fallback_height ~= nil and fallback_height > 0 then
		source_width = fallback_width
		source_height = fallback_height
	elseif source_width <= 0 or source_height <= 0 then
		source_width = fallback_width or source_width
		source_height = fallback_height or source_height
	end

	local id = tostring(obs.obs_sceneitem_get_id(item))
	local base = saved_transforms[id] or current
	if current == nil or source_width <= 0 or source_height <= 0 then
		release_item(item)
		print("[Screen Studio Lite] Auto Zoom could not read source size.")
		return
	end

	source_x = clamp(source_x, 0, source_width)
	source_y = clamp(source_y, 0, source_height)

	local base_free_scale = base_free_scale_for_zoom(base, source_width, source_height)
	if base.bounds_type ~= obs.OBS_BOUNDS_NONE and base.bounds_x > 0 and base.bounds_y > 0 then
		set_transform(item, {
			pos_x = base.pos_x,
			pos_y = base.pos_y,
			scale_x = base_free_scale,
			scale_y = base_free_scale,
			rot = base.rot,
			alignment = ALIGN_TOP_LEFT,
			bounds_type = obs.OBS_BOUNDS_NONE,
			bounds_alignment = base.bounds_alignment,
			bounds_x = 0,
			bounds_y = 0,
			crop_to_bounds = false,
		})
	end
	local target = zoom_transform_for_source_point(base, source_x, source_y, source_width, source_height, base_free_scale, zoom_override)

	local click_duration = math.max(settings_state.zoom_duration_ms or 0, 520)
	obs.timer_remove(restore_frame_layer_tick)
	set_frame_layer_visible(false)
	remove_round_mask_for_scene_item(item)
	zoom_camera_active_until = now_ms() + settings_state.click_reset_delay_ms + click_duration + 900
	last_cursor_time = now_ms()
	enqueue_animation(item, target, click_duration, "screen-studio")
	schedule_click_reset(item, click_duration)
	release_item(item)
	return target
end

function add_zoom_chapter(label)
	if not settings_state.zoom_adds_chapter then
		return
	end

	if not recording_active() then
		return
	end

	if obs.obs_frontend_recording_add_chapter ~= nil then
		obs.obs_frontend_recording_add_chapter(label or "Zoom")
	end
end

local parse_state_file
local click_capture_area
local upsert_round_mask_for_scene_item

function zoom_from_state_point(state, label, zoom_override)
	if state == nil then
		return false
	end

	if pending_click_reset ~= nil and label ~= "Click Zoom" then
		return false
	end

	local area_x, area_y, area_width, area_height = click_capture_area(state)
	if area_width == nil or area_height == nil or area_width <= 0 or area_height <= 0 then
		return false
	end

	local point_x = state.x
	local point_y = state.y
	if point_x == nil or point_y == nil then
		return false
	end
	if label == "Dwell Zoom" and point_x <= 0 and point_y <= 0 then
		return false
	end

	if point_x < area_x or point_y < area_y or point_x > (area_x + area_width) or point_y > (area_y + area_height) then
		return false
	end

	local item = nil
	item = find_zoom_target_scene_item()
	if item == nil then
		print("[Screen Studio Lite] Click detected, but no zoom target source was found.")
		return false
	end

	local source_width, source_height = item_size(item)
	if settings_state.studio_exclude_taskbar
		and settings_state.click_area_mode == "primary"
		and state.primary_width ~= nil
		and state.primary_height ~= nil
		and state.primary_width > 0
		and state.primary_height > 0 then
		source_width = (area_width / state.primary_width) * source_width
		source_height = (area_height / state.primary_height) * source_height
	end
	release_item(item)

	if source_width <= 0 or source_height <= 0 then
		source_width = area_width
		source_height = area_height
	end

	local source_x = ((point_x - area_x) / area_width) * source_width
	local source_y = ((point_y - area_y) / area_height) * source_height
	local active_zoom = zoom_override or settings_state.click_zoom_scale
	local target_transform = zoom_selected_to_source_point(source_x, source_y, source_width, source_height, active_zoom)
	local should_mark_recording_zoom = label ~= "Typing Zoom"
	if should_mark_recording_zoom then
		add_zoom_chapter(label)
	end
	write_live_status(label or "Zoom", point_x, point_y, active_zoom, target_transform)
	if label == "Click Zoom" then
		show_click_cursor_state()
		last_click_zoom_time = now_ms()
		last_auto_focus_time = now_ms()
		last_auto_focus_x = point_x
		last_auto_focus_y = point_y
		dwell_anchor_x = nil
		dwell_anchor_y = nil
		dwell_started_at = 0
	end
	if should_mark_recording_zoom and recording_active() then
		append_timeline(label or "Zoom", "focus", math.floor(point_x), math.floor(point_y), active_zoom)
	end
	print("[Screen Studio Lite] " .. tostring(label or "Zoom") .. " at x=" .. tostring(math.floor(point_x)) .. ", y=" .. tostring(math.floor(point_y)))
	return true
end

function zoom_to_latest_cursor_click()
	local state = parse_state_file()
	if state == nil then
		print("[Screen Studio Lite] Cursor state is not ready. Start the cursor watcher first.")
		return
	end

	if not zoom_from_state_point(state, "Cursor Zoom") then
		print("[Screen Studio Lite] Could not read cursor area size.")
	end
end

parse_state_file = function()
	local file = io.open(CLICK_STATE_PATH, "r")
	if file == nil then
		return nil
	end

	local text = file:read("*a")
	file:close()

	local values = {}
	for line in string.gmatch(text, "[^\r\n]+") do
		local key, value = string.match(line, "^([^=]+)=(.*)$")
		if key ~= nil then
			values[key] = tonumber(value) or value
		end
	end

	return values
end

function taskbar_safe_primary_area(state)
	if state == nil then
		return nil
	end

	local primary_width = state.primary_width or 0
	local primary_height = state.primary_height or 0
	local work_width = state.work_width or 0
	local work_height = state.work_height or 0
	if primary_width <= 0 or primary_height <= 0 or work_width <= 0 or work_height <= 0 then
		return nil
	end

	local work_x = state.work_x or 0
	local work_y = state.work_y or 0
	if work_width >= primary_width and work_height >= primary_height and work_x == 0 and work_y == 0 then
		return 0, 0, primary_width, primary_height
	end

	return work_x, work_y, work_width, work_height
end

function apply_taskbar_crop_to_zoom_target(state)
	if pending_click_reset ~= nil or zoom_camera_active_until > now_ms() then
		return
	end

	local item = find_zoom_target_scene_item(true)
	if item == nil then
		return
	end

	if not item_source_matches(item, { monitor_capture = true }) then
		release_item(item)
		return
	end

	if not settings_state.studio_exclude_taskbar then
		local crop_left, crop_top, crop_right, crop_bottom = scene_item_crop_values(item)
		if last_taskbar_crop_signature ~= "" or crop_left ~= 0 or crop_top ~= 0 or crop_right ~= 0 or crop_bottom ~= 0 then
			local crop = obs.obs_sceneitem_crop()
			crop.left = 0
			crop.top = 0
			crop.right = 0
			crop.bottom = 0
			obs.obs_sceneitem_set_crop(item, crop)
			if fit_item_to_canvas_area ~= nil then
				fit_item_to_canvas_area(item, true, false)
			end
			last_taskbar_crop_signature = ""
		end
		release_item(item)
		return
	end

	local safe_x, safe_y, safe_width, safe_height = taskbar_safe_primary_area(state)
	if safe_x == nil then
		release_item(item)
		return
	end

	local primary_width = state.primary_width or 0
	local primary_height = state.primary_height or 0
	local source_width, source_height = item_size(item)
	if primary_width <= 0 or primary_height <= 0 or source_width <= 0 or source_height <= 0 then
		release_item(item)
		return
	end

	local scale_x = source_width / primary_width
	local scale_y = source_height / primary_height
	local left = math.max(0, math.floor((safe_x * scale_x) + 0.5))
	local top = math.max(0, math.floor((safe_y * scale_y) + 0.5))
	local right = math.max(0, math.floor(((primary_width - (safe_x + safe_width)) * scale_x) + 0.5))
	local bottom = math.max(0, math.floor(((primary_height - (safe_y + safe_height)) * scale_y) + 0.5))
	local signature = tostring(obs.obs_sceneitem_get_id(item)) .. ":" .. tostring(left) .. "," .. tostring(top) .. "," .. tostring(right) .. "," .. tostring(bottom)

	if signature ~= last_taskbar_crop_signature then
		local crop = obs.obs_sceneitem_crop()
		crop.left = left
		crop.top = top
		crop.right = right
		crop.bottom = bottom
		obs.obs_sceneitem_set_crop(item, crop)
		if fit_item_to_canvas_area ~= nil then
			fit_item_to_canvas_area(item, true, false)
		end
		upsert_round_mask_for_scene_item(item)
		last_taskbar_crop_signature = signature
		print("[Screen Studio Lite] Taskbar excluded with crop L/T/R/B = " .. tostring(left) .. "/" .. tostring(top) .. "/" .. tostring(right) .. "/" .. tostring(bottom))
	end

	release_item(item)
end

click_capture_area = function(state)
	if state == nil then
		return nil
	end

	if settings_state.click_area_mode == "manual" then
		return settings_state.click_manual_x, settings_state.click_manual_y, settings_state.click_manual_width, settings_state.click_manual_height
	end

	if settings_state.click_area_mode == "virtual" then
		return state.virtual_x or 0, state.virtual_y or 0, state.virtual_width or 0, state.virtual_height or 0
	end

	if settings_state.studio_exclude_taskbar then
		local safe_x, safe_y, safe_width, safe_height = taskbar_safe_primary_area(state)
		if safe_x ~= nil then
			return safe_x, safe_y, safe_width, safe_height
		end
	end

	return 0, 0, state.primary_width or 0, state.primary_height or 0
end

function follow_zoom_to_pointer(state)
	if pending_click_reset == nil or pending_click_reset.item == nil then
		return
	end

	if state == nil or state.x == nil or state.y == nil then
		return
	end

	local item = pending_click_reset.item
	local id = tostring(obs.obs_sceneitem_get_id(item))
	if animations[id] ~= nil then
		return
	end

	local area_x, area_y, area_width, area_height = click_capture_area(state)
	if area_width == nil or area_height == nil or area_width <= 0 or area_height <= 0 then
		return
	end

	local point_x = clamp(state.x, area_x, area_x + area_width)
	local point_y = clamp(state.y, area_y, area_y + area_height)
	local source_width, source_height = item_size(item)
	if settings_state.studio_exclude_taskbar
		and settings_state.click_area_mode == "primary"
		and state.primary_width ~= nil
		and state.primary_height ~= nil
		and state.primary_width > 0
		and state.primary_height > 0 then
		source_width = (area_width / state.primary_width) * source_width
		source_height = (area_height / state.primary_height) * source_height
	end

	if source_width <= 0 or source_height <= 0 then
		source_width = area_width
		source_height = area_height
	end

	local base = saved_transforms[id] or current_transform(item)
	if base == nil then
		return
	end

	local source_x = ((point_x - area_x) / area_width) * source_width
	local source_y = ((point_y - area_y) / area_height) * source_height
	source_x = clamp(source_x, 0, source_width)
	source_y = clamp(source_y, 0, source_height)

	local desired = zoom_transform_for_source_point(base, source_x, source_y, source_width, source_height)
	local current = current_transform(item)
	if current ~= nil then
		local blend = 0.24
		desired.pos_x = current.pos_x + ((desired.pos_x - current.pos_x) * blend)
		desired.pos_y = current.pos_y + ((desired.pos_y - current.pos_y) * blend)
		desired.scale_x = current.scale_x + ((desired.scale_x - current.scale_x) * blend)
		desired.scale_y = current.scale_y + ((desired.scale_y - current.scale_y) * blend)
	end
	set_transform(item, desired)
end

function handle_click_state(state)
	if state == nil or state.event == nil then
		return
	end

	if last_click_event ~= nil and state.event <= last_click_event then
		return
	end
	last_click_event = state.event

	local current_ms = now_ms()
	if pending_click_reset ~= nil then
		show_click_cursor_state()
		return
	end

	if zoom_camera_active_until > current_ms then
		show_click_cursor_state()
	end

	if last_click_zoom_time > 0 and (current_ms - last_click_zoom_time) < 150 then
		return
	end

	if not settings_state.click_zoom_enabled then
		return
	end

	if not zoom_from_state_point(state, "Click Zoom") then
		print("[Screen Studio Lite] Auto Click Zoom could not read capture area size.")
	end
end

function update_cursor_scene_item(state)
	if not settings_state.visual_layer_cursor or state == nil or state.x == nil or state.y == nil then
		return
	end

	local now = now_ms()
	local pointer_moved = false
	if last_pointer_state_x == nil or last_pointer_state_y == nil then
		pointer_moved = true
	elseif math.abs(state.x - last_pointer_state_x) + math.abs(state.y - last_pointer_state_y) >= 2 then
		pointer_moved = true
	end
	if pointer_moved then
		last_pointer_activity_ms = now
		last_pointer_state_x = state.x
		last_pointer_state_y = state.y
		if pending_click_reset ~= nil then
			pending_click_reset.last_activity_ms = now
		end
	end

	local area_x, area_y, area_width, area_height = click_capture_area(state)
	if area_width == nil or area_height == nil or area_width <= 0 or area_height <= 0 then
		return
	end

	local canvas_width, canvas_height = preferred_canvas_size()
	local normalized_x = clamp((state.x - area_x) / area_width, 0.0, 1.0)
	local normalized_y = clamp((state.y - area_y) / area_height, 0.0, 1.0)
	local target_x = nil
	local target_y = nil
	local cursor_zoom = 1.0
	local zoom_item = find_zoom_target_scene_item(true)
	if zoom_item ~= nil then
		local transform = current_transform(zoom_item)
		if transform ~= nil then
			if transform.bounds_type ~= obs.OBS_BOUNDS_NONE and transform.bounds_x > 0 and transform.bounds_y > 0 then
				target_x = transform.pos_x + (normalized_x * transform.bounds_x)
				target_y = transform.pos_y + (normalized_y * transform.bounds_y)
				local source_width, source_height = item_size(zoom_item)
				if source_width > 0 and source_height > 0 then
					cursor_zoom = math.max(transform.bounds_x / source_width, transform.bounds_y / source_height)
				end
			else
				local source_width, source_height = item_size(zoom_item)
				local crop_left, crop_top, crop_right, crop_bottom = scene_item_crop_values(zoom_item)
				local visible_width = math.max(1, source_width - crop_left - crop_right)
				local visible_height = math.max(1, source_height - crop_top - crop_bottom)
				target_x = transform.pos_x + ((normalized_x * visible_width) * transform.scale_x)
				target_y = transform.pos_y + ((normalized_y * visible_height) * transform.scale_y)
				cursor_zoom = math.max(math.abs(transform.scale_x or 1), math.abs(transform.scale_y or 1), 1.0)
			end
		end
		release_item(zoom_item)
	end

	if target_x == nil or target_y == nil then
		target_x = normalized_x * canvas_width
		target_y = normalized_y * canvas_height
	end

	local raw_moved = false
	if last_raw_cursor_x == nil or last_raw_cursor_y == nil then
		raw_moved = true
	else
		raw_moved = math.abs(target_x - last_raw_cursor_x) + math.abs(target_y - last_raw_cursor_y) > 0.8
	end
	if raw_moved then
		last_cursor_time = now
		last_raw_cursor_x = target_x
		last_raw_cursor_y = target_y
	end

	if smoothed_cursor_x == nil or smoothed_cursor_y == nil then
		smoothed_cursor_x = target_x
		smoothed_cursor_y = target_y
	elseif pending_click_reset ~= nil or zoom_camera_active_until > now_ms() then
		smoothed_cursor_x = target_x
		smoothed_cursor_y = target_y
	else
		smoothed_cursor_x = target_x
		smoothed_cursor_y = target_y
	end

	local item = find_scene_item_by_source_names({ settings_state.cursor_layer_source_name })
	if item == nil then
		return
	end

	local moved = raw_moved or math.abs(target_x - smoothed_cursor_x) + math.abs(target_y - smoothed_cursor_y) > 0.8

	local clicked = state.event ~= nil and state.event > last_cursor_event
	if clicked then
		last_cursor_time = now
		show_click_cursor_state()
	end

	local should_show = true
	obs.obs_sceneitem_set_visible(item, should_show)

	local target = current_transform(item)
	if target ~= nil then
		local base_scale = settings_state.visual_layer_cursor_scale
		if clicked then
			last_cursor_event = state.event
			base_scale = base_scale * 1.08
		end
		if pending_click_reset ~= nil or zoom_camera_active_until > now_ms() then
			base_scale = base_scale * clamp(cursor_zoom, 1.0, 1.35)
		end

		local hotspot_x = clicked and CURSOR_CLICK_HOTSPOT_X or CURSOR_HOTSPOT_X
		local hotspot_y = clicked and CURSOR_CLICK_HOTSPOT_Y or CURSOR_HOTSPOT_Y
		local cursor_width, cursor_height = item_size(item)
		local min_cursor_x = -(cursor_width * base_scale) + 4
		local min_cursor_y = -(cursor_height * base_scale) + 4
		local max_cursor_x = canvas_width - 4
		local max_cursor_y = canvas_height - 4
		target.pos_x = clamp(smoothed_cursor_x - (hotspot_x * base_scale), min_cursor_x, max_cursor_x)
		target.pos_y = clamp(smoothed_cursor_y - (hotspot_y * base_scale), min_cursor_y, max_cursor_y)
		target.scale_x = base_scale
		target.scale_y = base_scale
		target.alignment = ALIGN_TOP_LEFT
		target.bounds_type = obs.OBS_BOUNDS_NONE
		target.bounds_x = 0
		target.bounds_y = 0
		target.crop_to_bounds = false
		set_transform(item, target)
	end

	release_item(item)
end

function handle_dwell_focus(state)
	if not settings_state.auto_focus_enabled or not settings_state.click_zoom_enabled then
		return
	end

	if state == nil or state.x == nil or state.y == nil or state.time == nil then
		return
	end

	local now = state.time
	local click_dwell_cooldown = math.max(settings_state.auto_focus_cooldown_ms, settings_state.click_reset_delay_ms)
	if last_click_zoom_time > 0 and (now_ms() - last_click_zoom_time) < click_dwell_cooldown then
		return
	end
	if last_auto_focus_time > 0 and (now - last_auto_focus_time) < settings_state.auto_focus_cooldown_ms then
		return
	end

	if dwell_anchor_x == nil or dwell_anchor_y == nil then
		dwell_anchor_x = state.x
		dwell_anchor_y = state.y
		dwell_started_at = now
		return
	end

	local distance = math.sqrt(((state.x - dwell_anchor_x) * (state.x - dwell_anchor_x)) + ((state.y - dwell_anchor_y) * (state.y - dwell_anchor_y)))
	if distance > settings_state.auto_focus_move_threshold then
		dwell_anchor_x = state.x
		dwell_anchor_y = state.y
		dwell_started_at = now
		return
	end

	if last_auto_focus_x ~= nil and last_auto_focus_y ~= nil then
		local refocus_distance = math.sqrt(((state.x - last_auto_focus_x) * (state.x - last_auto_focus_x)) + ((state.y - last_auto_focus_y) * (state.y - last_auto_focus_y)))
		if refocus_distance <= settings_state.auto_focus_move_threshold then
			return
		end
	end

	if (now - dwell_started_at) >= settings_state.auto_focus_dwell_ms and zoom_from_state_point(state, "Dwell Zoom") then
		last_auto_focus_time = now
		last_auto_focus_x = state.x
		last_auto_focus_y = state.y
		dwell_anchor_x = nil
		dwell_anchor_y = nil
		dwell_started_at = 0
	end
end

function key_combo_is_text_input(combo)
	if combo == nil or combo == "" then
		return false
	end

	if string.find(combo, "Ctrl", 1, true) ~= nil
		or string.find(combo, "Alt", 1, true) ~= nil
		or string.find(combo, "Win", 1, true) ~= nil then
		return false
	end

	local key = tostring(combo):gsub("^Shift%+", "")
	if key == "Esc"
		or key == "Left"
		or key == "Right"
		or key == "Up"
		or key == "Down"
		or string.match(key, "^F%d+$") ~= nil then
		return false
	end

	return true
end

function focus_state_from_text_caret(state)
	if state == nil then
		return nil
	end

	if state.caret_valid ~= 1 or state.caret_x == nil or state.caret_y == nil then
		return state
	end

	local focus_state = {}
	for key, value in pairs(state) do
		focus_state[key] = value
	end
	focus_state.x = state.caret_x
	focus_state.y = state.caret_y
	return focus_state
end

function handle_text_focus(state)
	if not settings_state.text_focus_enabled or not settings_state.click_zoom_enabled then
		return
	end

	if state == nil or state.key_event == nil then
		return
	end

	if settings_state._last_text_key_event == nil then
		settings_state._last_text_key_event = state.key_event
		return
	end

	if state.key_event <= settings_state._last_text_key_event then
		return
	end
	settings_state._last_text_key_event = state.key_event

	if not key_combo_is_text_input(state.key_combo) then
		return
	end

	local now = state.time or now_ms()
	if settings_state._last_text_focus_time ~= nil
		and settings_state._last_text_focus_time > 0
		and (now - settings_state._last_text_focus_time) < settings_state.text_focus_cooldown_ms then
		return
	end

	local focus_state = focus_state_from_text_caret(state)
	if focus_state == nil then
		return
	end

	if zoom_from_state_point(focus_state, "Typing Zoom", settings_state.typing_zoom_scale) then
		settings_state._last_text_focus_time = now
		settings_state._last_text_focus_x = focus_state.x
		settings_state._last_text_focus_y = focus_state.y
		last_auto_focus_time = now
		last_auto_focus_x = focus_state.x
		last_auto_focus_y = focus_state.y
		dwell_anchor_x = nil
		dwell_anchor_y = nil
		dwell_started_at = 0
	end
end

function click_poll_tick()
	local state = parse_state_file()
	apply_taskbar_crop_to_zoom_target(state)
	update_cursor_scene_item(state)
	follow_zoom_to_pointer(state)
	handle_click_state(state)
	handle_text_focus(state)
	handle_dwell_focus(state)
end

function sync_last_click_event()
	local state = parse_state_file()
	if state ~= nil and state.event ~= nil then
		last_click_event = state.event
	end
	obs.timer_remove(sync_last_click_event)
end

function stop_existing_click_helpers()
	local file = io.open(CLICK_STOP_PATH, "w")
	if file ~= nil then
		file:write("stop")
		file:close()
	end
	os.execute('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 350"')
	os.remove(CLICK_STOP_PATH)
end

function launch_click_helper()
	local command = "cmd.exe /C start \"\" /MIN " .. quote_arg(HELPER_LAUNCHER_PATH)
	os.execute(command)
end

function verify_click_helper_started()
	obs.timer_remove(verify_click_helper_started)
	if not click_zoom_running then
		return
	end
	if file_exists(CLICK_STATE_PATH) then
		return
	end
	print("[Screen Studio Lite] Cursor helper did not report state yet; relaunching.")
	launch_click_helper()
	obs.timer_add(verify_click_helper_started, 2500)
end

function start_click_zoom_watcher(enable_zoom)
	if click_zoom_running then
		if not file_exists(CLICK_STATE_PATH) then
			launch_click_helper()
			obs.timer_remove(verify_click_helper_started)
			obs.timer_add(verify_click_helper_started, 2500)
		end
		if enable_zoom == true then
			settings_state.click_zoom_enabled = true
		end
		return
	end

	stop_existing_click_helpers()
	os.remove(CLICK_STATE_PATH)
	settings_state.click_zoom_enabled = enable_zoom == true
	click_zoom_running = true
	last_click_event = 0
	dwell_anchor_x = nil
	dwell_anchor_y = nil
	dwell_started_at = 0
	last_auto_focus_time = 0
	last_auto_focus_x = nil
	last_auto_focus_y = nil
	settings_state._last_text_key_event = nil
	settings_state._last_text_focus_time = 0
	settings_state._last_text_focus_x = nil
	settings_state._last_text_focus_y = nil
	last_cursor_event = 0
	last_cursor_time = 0
	last_raw_cursor_x = nil
	last_raw_cursor_y = nil
	last_pointer_activity_ms = 0
	last_pointer_state_x = nil
	last_pointer_state_y = nil
	smoothed_cursor_x = nil
	smoothed_cursor_y = nil

	launch_click_helper()
	obs.timer_remove(click_poll_tick)
	obs.timer_remove(sync_last_click_event)
	obs.timer_remove(verify_click_helper_started)
	obs.timer_add(click_poll_tick, 16)
	obs.timer_add(verify_click_helper_started, 2500)
	print("[Screen Studio Lite] Cursor watcher started" .. (settings_state.click_zoom_enabled and " with click zoom." or " for cursor style only."))
end

function stop_click_zoom_watcher()
	settings_state.click_zoom_enabled = false
	click_zoom_running = false

	local file = io.open(CLICK_STOP_PATH, "w")
	if file ~= nil then
		file:write("stop")
		file:close()
	end

	obs.timer_remove(click_poll_tick)
	obs.timer_remove(sync_last_click_event)
	obs.timer_remove(verify_click_helper_started)
	print("[Screen Studio Lite] Auto Click Zoom watcher stopped.")
end

local ensure_click_zoom_watcher
local full_studio_setup_button
local finalize_recording_project
local apply_studio_recording_profile

finalize_recording_project = function()
	obs.timer_remove(finalize_recording_project)

	local recording_path = ""
	if obs.obs_frontend_get_last_recording ~= nil then
		recording_path = obs.obs_frontend_get_last_recording() or ""
	end
	if (recording_path == nil or recording_path == "") and obs.obs_frontend_get_current_record_output_path ~= nil then
		recording_path = obs.obs_frontend_get_current_record_output_path() or ""
	end

	last_recording_path = recording_path or ""
	write_timeline_json()
	write_studio_project(last_recording_path)
	print("[Screen Studio Lite] Studio project updated: " .. STUDIO_PROJECT_PATH)
	if last_recording_path ~= "" then
		print("[Screen Studio Lite] Last recording: " .. last_recording_path)
	end
end

function recording_tick()
	local active = false
	if obs.obs_frontend_recording_active ~= nil then
		active = obs.obs_frontend_recording_active()
	end

	if active and not recording_was_active then
		recording_was_active = true
		if timeline_started_ms <= 0 then
			reset_timeline()
			append_timeline("Start Recording", "OBS recording")
		end
		if settings_state.studio_recording_starts_watcher then
			ensure_click_zoom_watcher()
		end
	elseif not active and recording_was_active then
		recording_was_active = false
		obs.timer_remove(finalize_recording_project)
		obs.timer_add(finalize_recording_project, 1200)
	end
end

function auto_setup_tick()
	obs.timer_remove(auto_setup_tick)
	if settings_state.studio_auto_apply_4k_profile then
		apply_studio_recording_profile()
	end
	if settings_state.studio_auto_setup_on_load then
		print("[Screen Studio Lite] Auto setup on load.")
		full_studio_setup_button()
	end
	if not file_exists(STUDIO_PROJECT_PATH) then
		write_timeline_json()
		write_studio_project(last_recording_path)
	end
	if settings_state.visual_layer_cursor or settings_state.studio_auto_start_zoom_on_load then
		ensure_click_zoom_watcher()
	end
end

ensure_click_zoom_watcher = function()
	if not click_zoom_running then
		start_click_zoom_watcher(true)
	elseif not settings_state.click_zoom_enabled then
		settings_state.click_zoom_enabled = true
	end
end

function start_auto_zoom_button()
	start_click_zoom_watcher(true)
	return false
end

function stop_auto_zoom_button()
	stop_click_zoom_watcher()
	return false
end

local upsert_round_mask_for_source

function make_browser_settings(width, height, mode)
	local settings = obs.obs_data_create()
	obs.obs_data_set_bool(settings, "is_local_file", false)
	obs.obs_data_set_bool(settings, "local_file", false)
	if mode == "cursor" then
		obs.obs_data_set_string(settings, "url", file_url(CURSOR_HTML_PATH))
	else
		obs.obs_data_set_string(settings, "url", visual_layer_url(mode))
	end
	obs.obs_data_set_int(settings, "width", width)
	obs.obs_data_set_int(settings, "height", height)
	obs.obs_data_set_int(settings, "fps", 60)
	obs.obs_data_set_bool(settings, "shutdown", false)
	obs.obs_data_set_bool(settings, "restart_when_active", true)
	obs.obs_data_set_bool(settings, "reroute_audio", false)
	return settings
end

function make_cursor_browser_settings()
	local settings = obs.obs_data_create()
	obs.obs_data_set_bool(settings, "is_local_file", false)
	obs.obs_data_set_bool(settings, "local_file", false)
	obs.obs_data_set_string(settings, "url", cursor_layer_url(false))
	obs.obs_data_set_int(settings, "width", 220)
	obs.obs_data_set_int(settings, "height", 220)
	obs.obs_data_set_int(settings, "fps", 60)
	obs.obs_data_set_bool(settings, "shutdown", false)
	obs.obs_data_set_bool(settings, "restart_when_active", true)
	obs.obs_data_set_bool(settings, "reroute_audio", false)
	return settings
end

function make_camera_placeholder_settings()
	local settings = obs.obs_data_create()
	obs.obs_data_set_bool(settings, "is_local_file", false)
	obs.obs_data_set_bool(settings, "local_file", false)
	obs.obs_data_set_string(settings, "url", file_url(CAMERA_PLACEHOLDER_HTML_PATH) .. "?accent=" .. url_encode(settings_state.visual_cursor_accent))
	obs.obs_data_set_int(settings, "width", 640)
	obs.obs_data_set_int(settings, "height", 640)
	obs.obs_data_set_int(settings, "fps", 30)
	obs.obs_data_set_bool(settings, "shutdown", false)
	obs.obs_data_set_bool(settings, "restart_when_active", true)
	obs.obs_data_set_bool(settings, "reroute_audio", false)
	return settings
end

function camera_overlay_rect()
	local canvas_width, canvas_height = preferred_canvas_size()
	local size = math.min(canvas_width, canvas_height) * (settings_state.camera_size_pct / 100.0)
	local margin = settings_state.camera_margin
	local x = canvas_width - size - margin
	local y = canvas_height - size - margin

	if settings_state.camera_position == "bottom-left" then
		x = margin
		y = canvas_height - size - margin
	elseif settings_state.camera_position == "top-right" then
		x = canvas_width - size - margin
		y = margin
	elseif settings_state.camera_position == "top-left" then
		x = margin
		y = margin
	elseif settings_state.camera_position == "center" then
		x = (canvas_width - size) * 0.5
		y = canvas_height - size - margin
	end

	return x, y, size
end

function place_item_in_square_overlay(item, x, y, size)
	if item == nil then
		return
	end

	local target = current_transform(item)
	if target == nil then
		return
	end

	target.pos_x = x
	target.pos_y = y
	target.scale_x = 1
	target.scale_y = 1
	target.bounds_type = obs.OBS_BOUNDS_SCALE_INNER
	target.bounds_x = size
	target.bounds_y = size
	target.crop_to_bounds = true
	set_transform(item, target)
end

function camera_source_has_device(source)
	if source == nil then
		return false
	end

	local settings = obs.obs_source_get_settings(source)
	if settings == nil then
		return false
	end

	local has_device = false
	if obs.obs_data_has_user_value ~= nil then
		has_device = obs.obs_data_has_user_value(settings, "video_device_id")
			or obs.obs_data_has_user_value(settings, "device_id")
			or obs.obs_data_has_user_value(settings, "last_video_device_id")
	end
	if not has_device then
		local video_device_id = obs.obs_data_get_string(settings, "video_device_id")
		local device_id = obs.obs_data_get_string(settings, "device_id")
		local last_video_device_id = obs.obs_data_get_string(settings, "last_video_device_id")
		has_device = (video_device_id ~= nil and video_device_id ~= "")
			or (device_id ~= nil and device_id ~= "")
			or (last_video_device_id ~= nil and last_video_device_id ~= "")
	end

	obs.obs_data_release(settings)
	return has_device
end

function fit_item_to_canvas(item)
	local width, height = preferred_canvas_size()
	local target = current_transform(item)
	if target == nil then
		return
	end

	target.pos_x = 0
	target.pos_y = 0
	target.scale_x = 1
	target.scale_y = 1
	target.alignment = ALIGN_TOP_LEFT
	target.bounds_type = obs.OBS_BOUNDS_STRETCH
	target.bounds_x = width
	target.bounds_y = height
	target.crop_to_bounds = true
	set_transform(item, target)
end

function park_plain_color_sources_behind_visual_background(scene)
	if scene == nil then
		return
	end

	local parked_count = 0
	obs.obs_scene_enum_items(scene, function(_, item)
		local source = obs.obs_sceneitem_get_source(item)
		local name = source ~= nil and obs.obs_source_get_name(source) or ""
		local source_id = ""
		local unversioned_id = ""
		if source ~= nil and obs.obs_source_get_id ~= nil then
			source_id = obs.obs_source_get_id(source) or ""
		end
		if source ~= nil and obs.obs_source_get_unversioned_id ~= nil then
			unversioned_id = obs.obs_source_get_unversioned_id(source) or ""
		end
		local lower_name = string.lower(name or "")
		local is_plain_color = string.find(source_id, "color_source", 1, true) ~= nil
			or string.find(unversioned_id, "color_source", 1, true) ~= nil
			or name == "棰滆壊"
			or lower_name == "color"
			or lower_name == "colour"
		if is_plain_color
			and name ~= settings_state.card_source_name
			and name ~= settings_state.rectangle_source_name then
			obs.obs_sceneitem_set_visible(item, true)
			obs.obs_sceneitem_set_order(item, obs.OBS_ORDER_MOVE_BOTTOM)
			obs.obs_sceneitem_set_locked(item, false)
			parked_count = parked_count + 1
		end
		return true
	end, nil)

	for _, color_name in ipairs({ "棰滆壊", "Color", "Colour", "Color Source" }) do
		if color_name ~= settings_state.card_source_name and color_name ~= settings_state.rectangle_source_name then
			local item = obs.obs_scene_find_source(scene, color_name)
			if item ~= nil then
				obs.obs_sceneitem_set_visible(item, true)
				obs.obs_sceneitem_set_order(item, obs.OBS_ORDER_MOVE_BOTTOM)
				obs.obs_sceneitem_set_locked(item, false)
				parked_count = parked_count + 1
			end
		end
	end

	local background_item = obs.obs_scene_find_source(scene, settings_state.visual_layer_source_name)
	if background_item ~= nil then
		obs.obs_sceneitem_set_order(background_item, obs.OBS_ORDER_MOVE_BOTTOM)
	end

	if parked_count > 0 then
		print("[Screen Studio Lite] Plain color helper sources moved behind visual background: " .. tostring(parked_count))
	end
end

plain_color_cleanup_tick = function()
	obs.timer_remove(plain_color_cleanup_tick)
	local scene, scene_source = scene_source_from_frontend()
	if scene ~= nil then
		park_plain_color_sources_behind_visual_background(scene)
	end
	release_source(scene_source)
end

function add_or_update_visual_layer()
	local canvas_width, canvas_height = preferred_canvas_size()
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		release_source(scene_source)
		return
	end

	local layers = {
		{
			name = settings_state.visual_layer_source_name,
			mode = "background",
			order = obs.OBS_ORDER_MOVE_BOTTOM,
		},
		{
			name = settings_state.frame_layer_source_name,
			mode = "frame",
			order = obs.OBS_ORDER_MOVE_TOP,
		},
		{
			name = settings_state.cursor_layer_source_name,
			mode = "cursor",
			order = obs.OBS_ORDER_MOVE_TOP,
		},
	}

	for _, layer in ipairs(layers) do
		local source = obs.obs_get_source_by_name(layer.name)
		local settings = nil
		if layer.mode == "cursor" then
			settings = make_cursor_browser_settings()
		else
			settings = make_browser_settings(canvas_width, canvas_height, layer.mode)
		end

		if source == nil then
			source = obs.obs_source_create("browser_source", layer.name, settings, nil)
			if source == nil then
				print("[Screen Studio Lite] Could not create Browser source. Make sure obs-browser is installed.")
				obs.obs_data_release(settings)
			end
		else
			obs.obs_source_update(source, settings)
		end

		obs.obs_data_release(settings)

		if source ~= nil then
			local item = obs.obs_scene_find_source(scene, layer.name)
			if item == nil then
				item = obs.obs_scene_add(scene, source)
			end

			if item ~= nil then
				if layer.mode == "cursor" then
					local target = current_transform(item)
					if target ~= nil then
						target.scale_x = settings_state.visual_layer_cursor_scale
						target.scale_y = settings_state.visual_layer_cursor_scale
						target.alignment = ALIGN_TOP_LEFT
						target.bounds_type = obs.OBS_BOUNDS_NONE
						target.bounds_x = 0
						target.bounds_y = 0
						target.crop_to_bounds = false
						set_transform(item, target)
					end
					obs.obs_sceneitem_set_visible(item, settings_state.visual_layer_cursor)
				elseif layer.mode == "frame" then
					fit_item_to_canvas(item)
					obs.obs_sceneitem_set_visible(item, true)
				else
					fit_item_to_canvas(item)
					obs.obs_sceneitem_set_visible(item, true)
				end
				obs.obs_sceneitem_set_order(item, layer.order)
				obs.obs_sceneitem_set_locked(item, true)
			end

			obs.obs_source_release(source)
		end
	end

	park_plain_color_sources_behind_visual_background(scene)
	obs.timer_remove(plain_color_cleanup_tick)
	obs.timer_add(plain_color_cleanup_tick, 1800)
	release_source(scene_source)
	print("[Screen Studio Lite] Background and cursor layers are ready.")
end

color_background_sync_tick = function()
	if not settings_state.visual_bg_solid then
		return
	end

	local color = solid_background_color()
	if settings_state._last_solid_bg_color == color then
		return
	end

	settings_state._last_solid_bg_color = color
	add_or_update_visual_layer()
end

function apply_crop_to_selected(left, top, right, bottom)
	local item = nil
	item = find_selected_scene_item()
	if item == nil then
		print("[Screen Studio Lite] Select one source in the current scene first.")
		return
	end

	local crop = obs.obs_sceneitem_crop()
	crop.left = math.max(0, left)
	crop.top = math.max(0, top)
	crop.right = math.max(0, right)
	crop.bottom = math.max(0, bottom)
	obs.obs_sceneitem_set_crop(item, crop)
	release_item(item)
end

function create_or_add_source(source_id, source_name, settings)
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		release_source(scene_source)
		return nil
	end

	local source = obs.obs_get_source_by_name(source_name)
	if source == nil then
		source = obs.obs_source_create(source_id, source_name, settings, nil)
		if source == nil then
			print("[Screen Studio Lite] Could not create source: " .. source_name)
			release_source(scene_source)
			return nil
		end
	else
		obs.obs_source_update(source, settings)
	end

	local item = obs.obs_scene_find_source(scene, source_name)
	if item == nil then
		item = obs.obs_scene_add(scene, source)
	end

	if item ~= nil then
		obs.obs_sceneitem_addref(item)
	end

	obs.obs_source_release(source)
	release_source(scene_source)
	return item
end

function add_screen_capture()
	local settings = obs.obs_data_create()
	obs.obs_data_set_bool(settings, "capture_cursor", false)
	obs.obs_data_set_bool(settings, "capture_cursor_enabled", false)
	local item = nil
	if settings_state.capture_source_name == nil
		or settings_state.capture_source_name == ""
		or settings_state.capture_source_name == "Screen Capture" then
		item = find_scene_item_by_source_ids({ monitor_capture = true })
		if item ~= nil then
			local source = obs.obs_sceneitem_get_source(item)
			if source ~= nil then
				settings_state.capture_source_name = obs.obs_source_get_name(source)
				settings_state.zoom_target_source_name = settings_state.capture_source_name
				local existing_settings = obs.obs_source_get_settings(source)
				if existing_settings ~= nil then
					local current_monitor_id = obs.obs_data_get_string(existing_settings, "monitor_id")
					if current_monitor_id ~= nil and current_monitor_id ~= "" then
						obs.obs_data_set_string(settings, "monitor_id", current_monitor_id)
					end
					obs.obs_data_release(existing_settings)
				end
				obs.obs_source_update(source, settings)
				print("[Screen Studio Lite] Reusing current screen source: " .. settings_state.capture_source_name)
			end
		end
	end

	if item == nil then
		item = create_or_add_source("monitor_capture", settings_state.capture_source_name, settings)
	end
	obs.obs_data_release(settings)
	settings_state.zoom_target_source_name = settings_state.capture_source_name
	print("[Screen Studio Lite] Auto Zoom target set to: " .. settings_state.zoom_target_source_name)

	if item ~= nil then
		obs.obs_sceneitem_set_visible(item, true)
		if fit_item_to_canvas_area ~= nil then
			fit_item_to_canvas_area(item, true, false)
		else
			fit_item_to_canvas(item)
		end
		upsert_round_mask_for_scene_item(item)
		obs.obs_sceneitem_set_order(item, obs.OBS_ORDER_MOVE_UP)
		select_only_scene_item(item)
		release_item(item)
	end
end

function add_window_capture()
	local settings = obs.obs_data_create()
	obs.obs_data_set_bool(settings, "capture_cursor", false)
	obs.obs_data_set_bool(settings, "capture_cursor_enabled", false)
	local item = create_or_add_source("window_capture", settings_state.window_source_name, settings)
	obs.obs_data_release(settings)
	settings_state.zoom_target_source_name = settings_state.window_source_name
	print("[Screen Studio Lite] Auto Zoom target set to: " .. settings_state.zoom_target_source_name)

	if item ~= nil then
		obs.obs_sceneitem_set_visible(item, true)
		if fit_item_to_canvas_area ~= nil then
			fit_item_to_canvas_area(item, true, false)
		else
			fit_item_to_canvas(item)
		end
		remove_round_mask_for_scene_item(item)
		select_only_scene_item(item)
		release_item(item)
	end
end

function add_area_capture()
	local settings = obs.obs_data_create()
	obs.obs_data_set_bool(settings, "capture_cursor", false)
	obs.obs_data_set_bool(settings, "capture_cursor_enabled", false)
	local item = create_or_add_source("monitor_capture", settings_state.area_source_name, settings)
	obs.obs_data_release(settings)
	settings_state.zoom_target_source_name = settings_state.area_source_name
	print("[Screen Studio Lite] Auto Zoom target set to: " .. settings_state.zoom_target_source_name)

	if item ~= nil then
		obs.obs_sceneitem_set_visible(item, true)
		if fit_item_to_canvas_area ~= nil then
			fit_item_to_canvas_area(item, true, false)
		else
			fit_item_to_canvas(item)
		end
		local crop = obs.obs_sceneitem_crop()
		crop.left = math.max(0, settings_state.area_crop_left)
		crop.top = math.max(0, settings_state.area_crop_top)
		crop.right = math.max(0, settings_state.area_crop_right)
		crop.bottom = math.max(0, settings_state.area_crop_bottom)
		obs.obs_sceneitem_set_crop(item, crop)
		remove_round_mask_for_scene_item(item)
		select_only_scene_item(item)
		release_item(item)
	end
end

function add_camera_source()
	if not settings_state.camera_enabled then
		local scene, scene_source = scene_source_from_frontend()
		if scene ~= nil then
			for _, source_name in ipairs({
				settings_state.camera_source_name,
				settings_state.camera_placeholder_source_name,
				"Camera",
				CAMERA_PLACEHOLDER_SOURCE_NAME,
			}) do
				if source_name ~= nil and source_name ~= "" then
					local item = obs.obs_scene_find_source(scene, source_name)
					if item ~= nil then
						obs.obs_sceneitem_remove(item)
					end
				end
			end
		end
		release_source(scene_source)
		return
	end

	local overlay_x, overlay_y, overlay_size = camera_overlay_rect()
	local placeholder_settings = make_camera_placeholder_settings()
	local placeholder_item = create_or_add_source("browser_source", settings_state.camera_placeholder_source_name, placeholder_settings)
	obs.obs_data_release(placeholder_settings)
	if placeholder_item ~= nil then
		place_item_in_square_overlay(placeholder_item, overlay_x, overlay_y, overlay_size)
		obs.obs_sceneitem_set_order(placeholder_item, obs.OBS_ORDER_MOVE_TOP)
		release_item(placeholder_item)
	end

	local settings = obs.obs_data_create()
	local item = create_or_add_source("dshow_input", settings_state.camera_source_name, settings)
	obs.obs_data_release(settings)

	if item ~= nil then
		place_item_in_square_overlay(item, overlay_x, overlay_y, overlay_size)
		local source = obs.obs_sceneitem_get_source(item)
		local has_device = camera_source_has_device(source)
		obs.obs_sceneitem_set_visible(item, has_device)
		if not has_device then
			print("[Screen Studio Lite] Camera has no configured device; showing camera placeholder.")
		end
		if upsert_round_mask_for_source ~= nil then
			upsert_round_mask_for_source(source)
		end
		obs.obs_sceneitem_set_order(item, obs.OBS_ORDER_MOVE_TOP)
		release_item(item)
	end
end

function add_default_audio_source(source_id, source_name)
	local settings = obs.obs_data_create()
	obs.obs_data_set_string(settings, "device_id", "default")
	local item = create_or_add_source(source_id, source_name, settings)
	obs.obs_data_release(settings)
	release_item(item)
end

apply_studio_recording_profile = function()
	local config = obs.obs_frontend_get_profile_config()
	if config == nil then
		print("[Screen Studio Lite] Could not access OBS profile config.")
		return false
	end

	local canvas_width, canvas_height, canvas_label = studio_canvas_settings()
	local file_path = settings_state.studio_profile_path
	if file_path == nil or file_path == "" then
		file_path = os.getenv("USERPROFILE") .. "\\Videos"
	end

	obs.config_set_string(config, "Output", "Mode", "Simple")
	obs.config_set_string(config, "SimpleOutput", "FilePath", file_path)
	obs.config_set_string(config, "SimpleOutput", "RecFormat2", "hybrid_mp4")
	obs.config_set_string(config, "SimpleOutput", "RecQuality", "HQ")
	obs.config_set_string(config, "SimpleOutput", "RecEncoder", "nvenc")
	obs.config_set_string(config, "SimpleOutput", "NVENCPreset2", "p6")
	obs.config_set_int(config, "SimpleOutput", "VBitrate", settings_state.studio_profile_bitrate)
	obs.config_set_int(config, "SimpleOutput", "ABitrate", 320)
	obs.config_set_int(config, "Video", "BaseCX", canvas_width)
	obs.config_set_int(config, "Video", "BaseCY", canvas_height)
	obs.config_set_int(config, "Video", "OutputCX", canvas_width)
	obs.config_set_int(config, "Video", "OutputCY", canvas_height)
	obs.config_set_string(config, "Video", "FPSCommon", "60")
	obs.config_set_string(config, "Video", "ScaleType", "lanczos")
	obs.config_set_string(config, "Video", "ColorSpace", "709")
	obs.config_set_string(config, "Video", "ColorRange", "Partial")
	obs.config_save_safe(config, "tmp", "bak")
	obs.obs_frontend_save()

	write_studio_project(last_recording_path)
	print("[Screen Studio Lite] Recording/export profile saved: " .. canvas_label .. " (" .. tostring(canvas_width) .. "x" .. tostring(canvas_height) .. ") at 60 fps.")
	return false
end

upsert_round_mask_for_source = function(source)
	if source == nil then
		return
	end

	local filter = obs.obs_source_get_filter_by_name(source, FILTER_NAME)
	local settings = obs.obs_data_create()
	obs.obs_data_set_int(settings, "type", settings_state.mask_type)
	obs.obs_data_set_string(settings, "image_path", current_mask_path())
	obs.obs_data_set_bool(settings, "stretch", true)

	if filter == nil then
		filter = obs.obs_source_create("mask_filter", FILTER_NAME, settings, nil)
		if filter ~= nil then
			obs.obs_source_filter_add(source, filter)
		end
	else
		obs.obs_source_update(filter, settings)
	end

	if filter ~= nil then
		obs.obs_source_release(filter)
	end

	obs.obs_data_release(settings)
end

function write_dynamic_mask_script()
	if file_exists(DYNAMIC_MASK_SCRIPT_PATH) then
		return
	end

	local file = io.open(DYNAMIC_MASK_SCRIPT_PATH, "w")
	if file == nil then
		return
	end

	file:write([[
param(
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$Width,
    [Parameter(Mandatory = $true)][int]$Height,
    [Parameter(Mandatory = $true)][int]$Left,
    [Parameter(Mandatory = $true)][int]$Top,
    [Parameter(Mandatory = $true)][int]$Right,
    [Parameter(Mandatory = $true)][int]$Bottom,
    [Parameter(Mandatory = $true)][int]$Radius
)

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $OutputPath
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$visibleWidth = [Math]::Max(1, $Width - $Left - $Right)
$visibleHeight = [Math]::Max(1, $Height - $Top - $Bottom)
$radius = [Math]::Min([Math]::Max(0, $Radius), [Math]::Floor([Math]::Min($visibleWidth, $visibleHeight) / 2))

$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

$rect = New-Object System.Drawing.Rectangle $Left, $Top, $visibleWidth, $visibleHeight
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
if ($radius -le 0) {
    $path.AddRectangle($rect)
} else {
    $diameter = $radius * 2
    $path.AddArc($rect.Left, $rect.Top, $diameter, $diameter, 180, 90)
    $path.AddArc($rect.Right - $diameter, $rect.Top, $diameter, $diameter, 270, 90)
    $path.AddArc($rect.Right - $diameter, $rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($rect.Left, $rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
}

$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$graphics.FillPath($brush, $path)
$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$brush.Dispose()
$path.Dispose()
$graphics.Dispose()
$bitmap.Dispose()
]])
	file:close()
end

function dynamic_mask_path(width, height, left, top, right, bottom, radius)
	return MASK_DIR .. "dynamic-" .. tostring(width) .. "x" .. tostring(height)
		.. "-crop-" .. tostring(left) .. "-" .. tostring(top) .. "-" .. tostring(right) .. "-" .. tostring(bottom)
		.. "-r" .. tostring(radius) .. ".png"
end

function ensure_dynamic_round_mask(width, height, left, top, right, bottom)
	local radius = corner_radius_for_source_height(height)
	local path = dynamic_mask_path(width, height, left, top, right, bottom, radius)
	if file_exists(path) then
		return path
	end

	write_dynamic_mask_script()
	local command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File " .. shell_quote(DYNAMIC_MASK_SCRIPT_PATH)
		.. " -OutputPath " .. shell_quote(path)
		.. " -Width " .. tostring(width)
		.. " -Height " .. tostring(height)
		.. " -Left " .. tostring(left)
		.. " -Top " .. tostring(top)
		.. " -Right " .. tostring(right)
		.. " -Bottom " .. tostring(bottom)
		.. " -Radius " .. tostring(radius)
	os.execute(command)

	if file_exists(path) then
		return path
	end

	return current_mask_path()
end

upsert_round_mask_for_scene_item = function(item)
	if item == nil then
		return
	end

	local source = obs.obs_sceneitem_get_source(item)
	if source == nil then
		return
	end

	local source_width, source_height = item_size(item)
	if source_width <= 0 or source_height <= 0 then
		upsert_round_mask_for_source(source)
		return
	end

	local left, top, right, bottom = scene_item_crop_values(item)
	local mask_path = ensure_dynamic_round_mask(source_width, source_height, left, top, right, bottom)
	local signature = tostring(obs.obs_sceneitem_get_id(item)) .. ":" .. tostring(mask_path)
	if signature == last_dynamic_mask_signature then
		return
	end

	local filter = obs.obs_source_get_filter_by_name(source, FILTER_NAME)
	local settings = obs.obs_data_create()
	obs.obs_data_set_int(settings, "type", settings_state.mask_type)
	obs.obs_data_set_string(settings, "image_path", mask_path)
	obs.obs_data_set_bool(settings, "stretch", false)

	if filter == nil then
		filter = obs.obs_source_create("mask_filter", FILTER_NAME, settings, nil)
		if filter ~= nil then
			obs.obs_source_filter_add(source, filter)
		end
	else
		obs.obs_source_update(filter, settings)
	end

	if filter ~= nil then
		obs.obs_source_release(filter)
	end

	obs.obs_data_release(settings)
	last_dynamic_mask_signature = signature
	print("[Screen Studio Lite] Rounded fullscreen mask updated: " .. mask_path)
end

function apply_fullscreen_round_mask()
	local item = find_zoom_target_scene_item(true)
	if item ~= nil then
		upsert_round_mask_for_scene_item(item)
		release_item(item)
	end
end

function apply_round_corners_selected()
	local item = nil
	item = find_selected_scene_item()
	if item == nil then
		print("[Screen Studio Lite] Select one source in the current scene first.")
		return
	end

	upsert_round_mask_for_scene_item(item)
	release_item(item)
end

fit_item_to_canvas_area = function(item, preserve_aspect, crop_to_bounds)
	if item == nil then
		return
	end

	local canvas_width, canvas_height = preferred_canvas_size()

	local max_width = math.max(64, canvas_width - (settings_state.card_margin * 2))
	local max_height = math.max(64, canvas_height - (settings_state.card_margin * 2))
	local target_width = max_width
	local target_height = max_height
	if preserve_aspect then
		local source_width, source_height = item_size(item)
		local crop_left, crop_top, crop_right, crop_bottom = scene_item_crop_values(item)
		local visible_width = math.max(1, source_width - crop_left - crop_right)
		local visible_height = math.max(1, source_height - crop_top - crop_bottom)
		if visible_width > 0 and visible_height > 0 then
			local aspect = visible_width / visible_height
			target_height = target_width / aspect
			if target_height > max_height then
				target_height = max_height
				target_width = target_height * aspect
			end
		end
	end
	local target = current_transform(item)
	if target == nil then
		return
	end

	target.pos_x = (canvas_width - target_width) * 0.5
	target.pos_y = (canvas_height - target_height) * 0.5
	target.scale_x = 1.0
	target.scale_y = 1.0
	target.alignment = ALIGN_TOP_LEFT
	target.bounds_type = preserve_aspect and obs.OBS_BOUNDS_SCALE_INNER or obs.OBS_BOUNDS_STRETCH
	target.bounds_x = target_width
	target.bounds_y = target_height
	target.crop_to_bounds = crop_to_bounds

	set_transform(item, target)
end

function center_item_at_natural_size(item)
	if item == nil then
		return
	end

	local canvas_width, canvas_height = preferred_canvas_size()

	local width, height = item_size(item)
	local target = current_transform(item)
	if target == nil then
		return
	end

	target.pos_x = (canvas_width - width) * 0.5
	target.pos_y = (canvas_height - height) * 0.5
	target.scale_x = 1.0
	target.scale_y = 1.0
	target.bounds_type = obs.OBS_BOUNDS_NONE
	target.bounds_x = 0
	target.bounds_y = 0
	target.crop_to_bounds = false

	set_transform(item, target)
end

function add_rounded_shape(source_name, send_to_bottom, fit_to_canvas)
	local scene, scene_source = scene_source_from_frontend()
	if scene == nil then
		if scene_source ~= nil then
			obs.obs_source_release(scene_source)
		end
		return
	end

	local settings = obs.obs_data_create()
	obs.obs_data_set_int(settings, "color", settings_state.card_color)
	obs.obs_data_set_int(settings, "width", settings_state.card_width)
	obs.obs_data_set_int(settings, "height", settings_state.card_height)

	local source = obs.obs_source_create("color_source", source_name, settings, nil)
	obs.obs_data_release(settings)

	if source == nil then
		print("[Screen Studio Lite] Could not create OBS Color source.")
		obs.obs_source_release(scene_source)
		return
	end

	upsert_round_mask_for_source(source)
	local item = obs.obs_scene_add(scene, source)
	if item ~= nil then
		if fit_to_canvas then
			fit_item_to_canvas_area(item, false, true)
		else
			center_item_at_natural_size(item)
		end

		if send_to_bottom then
			obs.obs_sceneitem_set_order(item, obs.OBS_ORDER_MOVE_BOTTOM)
		end
	end

	obs.obs_source_release(source)
	obs.obs_source_release(scene_source)
end

function add_rounded_card()
	add_rounded_shape(settings_state.card_source_name, true, true)
end

function add_rounded_rectangle()
	add_rounded_shape(settings_state.rectangle_source_name, false, false)
end

function apply_studio_look()
	local item = nil
	item = find_selected_scene_item()
	if item == nil then
		print("[Screen Studio Lite] Select one source in the current scene first.")
		return
	end

	save_original_transform(item)
	fit_item_to_canvas_area(item, true, false)
	upsert_round_mask_for_scene_item(item)
	release_item(item)

	if settings_state.create_background then
		add_rounded_card()
	end
end

function zoom_in_pressed(pressed)
	if pressed then
		zoom_selected(settings_state.zoom_step)
	end
end

function zoom_out_pressed(pressed)
	if pressed then
		zoom_selected(1.0 / settings_state.zoom_step)
	end
end

function reset_pressed(pressed)
	if pressed then
		reset_selected()
	end
end

function round_pressed(pressed)
	if pressed then
		apply_round_corners_selected()
	end
end

function zoom_cursor_pressed(pressed)
	if pressed then
		ensure_click_zoom_watcher()
		zoom_to_latest_cursor_click()
	end
end

function start_recording_pressed(pressed)
	if pressed then
		full_studio_setup_button()
		ensure_click_zoom_watcher()
		if obs.obs_frontend_recording_active ~= nil and not obs.obs_frontend_recording_active() then
			reset_timeline()
			append_timeline("Start Recording", "Hotkey")
			obs.obs_frontend_recording_start()
		end
	end
end

function stop_recording_pressed(pressed)
	if pressed then
		if obs.obs_frontend_recording_active ~= nil and obs.obs_frontend_recording_active() then
			append_timeline("Stop Recording", "Hotkey")
			obs.obs_frontend_recording_stop()
		end
	end
end

function mark_chapter_pressed(pressed)
	if pressed then
		if obs.obs_frontend_recording_add_chapter ~= nil then
			obs.obs_frontend_recording_add_chapter("Highlight")
		end
		append_timeline("Chapter", "Highlight")
	end
end

function zoom_in_button()
	zoom_selected(settings_state.zoom_step)
	return false
end

function zoom_out_button()
	zoom_selected(1.0 / settings_state.zoom_step)
	return false
end

function reset_button()
	reset_selected()
	return false
end

function round_button()
	apply_round_corners_selected()
	return false
end

function studio_button()
	apply_studio_look()
	return false
end

function card_button()
	add_rounded_card()
	return false
end

function rectangle_button()
	add_rounded_rectangle()
	return false
end

function visual_layer_button()
	add_or_update_visual_layer()
	return false
end

function set_zoom_target_button()
	local item = nil
	item = find_selected_scene_item()
	if item == nil then
		print("[Screen Studio Lite] Select the source you want Auto Zoom to control first.")
		return false
	end

	local source = obs.obs_sceneitem_get_source(item)
	if source ~= nil then
		settings_state.zoom_target_source_name = obs.obs_source_get_name(source)
		print("[Screen Studio Lite] Auto Zoom target set to: " .. settings_state.zoom_target_source_name)
	end
	release_item(item)
	return false
end

function screen_capture_button()
	add_screen_capture()
	return false
end

function window_capture_button()
	add_window_capture()
	return false
end

function area_capture_button()
	add_area_capture()
	return false
end

function camera_button()
	add_camera_source()
	return false
end

function mic_button()
	add_default_audio_source("wasapi_input_capture", settings_state.mic_source_name)
	return false
end

function system_audio_button()
	add_default_audio_source("wasapi_output_capture", settings_state.system_audio_source_name)
	return false
end

function zoom_cursor_button()
	ensure_click_zoom_watcher()
	zoom_to_latest_cursor_click()
	return false
end

function test_zoom_target_button()
	zoom_selected(settings_state.click_zoom_scale)
	return false
end

function mark_chapter_button()
	if obs.obs_frontend_recording_add_chapter ~= nil then
		obs.obs_frontend_recording_add_chapter("Highlight")
	end
	append_timeline("Chapter", "Highlight")
	return false
end

function split_recording_button()
	if obs.obs_frontend_recording_split_file ~= nil then
		obs.obs_frontend_recording_split_file()
		append_timeline("Split Recording", "")
	end
	return false
end

function pause_recording_button()
	if obs.obs_frontend_recording_pause ~= nil and obs.obs_frontend_recording_active ~= nil then
		if obs.obs_frontend_recording_active() then
			local paused = not obs.obs_frontend_recording_paused()
			obs.obs_frontend_recording_pause(paused)
			append_timeline(paused and "Pause Recording" or "Resume Recording", "")
		end
	end
	return false
end

function start_studio_recording_button()
	full_studio_setup_button()
	ensure_click_zoom_watcher()
	if obs.obs_frontend_recording_active ~= nil and not obs.obs_frontend_recording_active() then
		reset_timeline()
		append_timeline("Start Recording", "Screen Studio setup")
		obs.obs_frontend_recording_start()
		if settings_state.studio_recording_adds_chapters and obs.obs_frontend_recording_add_chapter ~= nil then
			obs.obs_frontend_recording_add_chapter("Start")
		end
	end
	return false
end

function stop_studio_recording_button()
	if obs.obs_frontend_recording_active ~= nil and obs.obs_frontend_recording_active() then
		if settings_state.studio_recording_adds_chapters and obs.obs_frontend_recording_add_chapter ~= nil then
			obs.obs_frontend_recording_add_chapter("End")
		end
		append_timeline("Stop Recording", "")
		obs.obs_frontend_recording_stop()
	end
	return false
end

function open_studio_editor_button()
	os.execute("start \"\" " .. quote_arg(STUDIO_EDITOR_PATH))
	return false
end

full_studio_setup_button = function()
	if settings_state.studio_auto_apply_4k_profile and apply_studio_recording_profile ~= nil then
		apply_studio_recording_profile()
	end
	use_studio_scene_if_enabled()
	add_screen_capture()
	add_camera_source()
	add_default_audio_source("wasapi_input_capture", settings_state.mic_source_name)
	add_default_audio_source("wasapi_output_capture", settings_state.system_audio_source_name)
	add_or_update_visual_layer()
	return false
end

function script_description()
	return [[
Screen Studio Lite for OBS

Select a source in the current scene, then use the buttons or hotkeys to zoom, reset, and apply rounded corners. It is a safe script-only layer: no OBS executable or DLL files are modified.

It can also build a Screen Studio style recording scene: full-screen/window/area capture, camera, microphone, system audio, a gradient product-card browser layer, smoothed cursor highlight, auto click zoom, rounded rectangles, and multi-aspect recording presets.
]]
end

function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_text(props, "quick_help", "Usage", obs.OBS_TEXT_INFO)
	obs.obs_properties_add_button(props, "start_studio_recording_button", "Start Studio Recording", start_studio_recording_button)
	obs.obs_properties_add_button(props, "stop_studio_recording_button", "Stop Studio Recording", stop_studio_recording_button)
	obs.obs_properties_add_button(props, "pause_recording_button", "Pause / Resume Recording", pause_recording_button)
	obs.obs_properties_add_button(props, "mark_chapter_button", "Add Chapter Marker", mark_chapter_button)
	obs.obs_properties_add_button(props, "split_recording_button", "Split Recording File", split_recording_button)
	obs.obs_properties_add_button(props, "open_studio_editor_button", "Open Studio Editor", open_studio_editor_button)
	obs.obs_properties_add_button(props, "full_studio_setup_button", "Create Full Studio Setup", full_studio_setup_button)
	obs.obs_properties_add_button(props, "visual_layer_button", "Add / Refresh Background + Cursor Layers", visual_layer_button)
	obs.obs_properties_add_button(props, "start_auto_zoom_button", "Start Auto Click Zoom + Cursor Watcher", start_auto_zoom_button)
	obs.obs_properties_add_button(props, "stop_auto_zoom_button", "Stop Auto Click Zoom + Cursor Watcher", stop_auto_zoom_button)
	obs.obs_properties_add_button(props, "set_zoom_target_button", "Use Selected Source For Auto Zoom", set_zoom_target_button)
	obs.obs_properties_add_button(props, "zoom_cursor_button", "Zoom To Current Cursor", zoom_cursor_button)
	obs.obs_properties_add_button(props, "test_zoom_target_button", "Test 2x Zoom Target", test_zoom_target_button)
	obs.obs_properties_add_button(props, "screen_capture_button", "Add Full Screen Capture", screen_capture_button)
	obs.obs_properties_add_button(props, "window_capture_button", "Add Window Capture", window_capture_button)
	obs.obs_properties_add_button(props, "area_capture_button", "Add Area Capture from Crop Values", area_capture_button)
	obs.obs_properties_add_button(props, "camera_button", "Add Camera Overlay", camera_button)
	obs.obs_properties_add_button(props, "mic_button", "Add Default Microphone", mic_button)
	obs.obs_properties_add_button(props, "system_audio_button", "Add Default System Audio", system_audio_button)
	obs.obs_properties_add_button(props, "apply_studio_recording_profile", "Apply Recording Aspect Preset", apply_studio_recording_profile)
	obs.obs_properties_add_button(props, "studio_button", "Apply Studio Look to Selected Source", studio_button)
	obs.obs_properties_add_button(props, "zoom_in_button", "Zoom In Selected Source", zoom_in_button)
	obs.obs_properties_add_button(props, "zoom_out_button", "Zoom Out Selected Source", zoom_out_button)
	obs.obs_properties_add_button(props, "reset_button", "Reset Selected Source", reset_button)
	obs.obs_properties_add_button(props, "round_button", "Apply Rounded Corners", round_button)
	obs.obs_properties_add_button(props, "card_button", "Add Rounded Background Card", card_button)
	obs.obs_properties_add_button(props, "rectangle_button", "Add Custom Rounded Rectangle", rectangle_button)

	local visual_style = obs.obs_properties_add_list(props, "visual_layer_style", "Visual Layer Background", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(visual_style, "Aurora", "aurora")
	obs.obs_property_list_add_string(visual_style, "Graphite", "graphite")
	obs.obs_property_list_add_string(visual_style, "Fresh", "fresh")
	obs.obs_property_list_add_string(visual_style, "Mono", "mono")

	obs.obs_properties_add_bool(props, "visual_layer_card", "Visual Layer draws product card")
	obs.obs_properties_add_bool(props, "visual_layer_cursor", "Visual Layer draws smoothed cursor")
	obs.obs_properties_add_bool(props, "visual_layer_touch_cursor", "Use touch cursor style")
	obs.obs_properties_add_bool(props, "visual_keystrokes", "Show shortcut keystrokes")
	obs.obs_properties_add_int_slider(props, "visual_keystroke_hold_ms", "Keystroke Hold Time (ms)", 300, 5000, 50)
	local keystroke_position = obs.obs_properties_add_list(props, "visual_keystroke_position", "Keystroke Position", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(keystroke_position, "Bottom", "bottom")
	obs.obs_property_list_add_string(keystroke_position, "Top", "top")
	obs.obs_properties_add_bool(props, "visual_cursor_rotate", "Rotate cursor toward movement")
	obs.obs_properties_add_float_slider(props, "visual_layer_cursor_scale", "Cursor Scale", 0.5, 3.0, 0.05)
	obs.obs_properties_add_int_slider(props, "visual_layer_idle_ms", "Hide Still Cursor After (ms)", 0, 5000, 50)
	obs.obs_properties_add_float_slider(props, "visual_layer_smoothing", "Cursor Smoothing", 0.02, 0.6, 0.01)
	obs.obs_properties_add_float_slider(props, "visual_cursor_shake_threshold", "Cursor Shake Reduction", 0.0, 12.0, 0.1)
	obs.obs_properties_add_text(props, "visual_cursor_color", "Cursor Color", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "visual_cursor_accent", "Cursor Accent Color", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "visual_click_color", "Click Ring Color", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_float_slider(props, "visual_card_inset", "Card Inset (%)", 0.0, 20.0, 0.1)
	obs.obs_properties_add_int_slider(props, "visual_card_radius", "Card Radius", 0, 96, 1)
	obs.obs_properties_add_int_slider(props, "visual_card_opacity", "Card Opacity", 0, 100, 1)
	obs.obs_properties_add_int_slider(props, "visual_shadow_strength", "Card Shadow Strength", 0, 80, 1)
	obs.obs_properties_add_bool(props, "visual_bg_solid", "Use OBS Color Source as Full Background")
	obs.obs_properties_add_text(props, "visual_bg_color_a", "Background Color A", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "visual_bg_color_b", "Background Color B", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "visual_bg_color_c", "Background Color C", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_path(props, "visual_bg_image", "Custom Background Image", obs.OBS_PATH_FILE, "Image Files (*.png *.jpg *.jpeg *.webp);;All Files (*.*)", "")
	obs.obs_properties_add_text(props, "visual_layer_source_name", "Background Layer Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "frame_layer_source_name", "Rounded Frame Layer Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "cursor_layer_source_name", "Cursor Layer Source Name", obs.OBS_TEXT_DEFAULT)

	obs.obs_properties_add_text(props, "zoom_target_source_name", "Auto Zoom Target Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "capture_source_name", "Full Screen Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "window_source_name", "Window Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "area_source_name", "Area Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_bool(props, "studio_use_dedicated_scene", "Use dedicated Studio scene")
	obs.obs_properties_add_text(props, "studio_scene_name", "Studio Scene Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_bool(props, "camera_enabled", "Show Camera Overlay")
	obs.obs_properties_add_text(props, "camera_source_name", "Camera Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "camera_placeholder_source_name", "Camera Placeholder Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "mic_source_name", "Microphone Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "system_audio_source_name", "System Audio Source Name", obs.OBS_TEXT_DEFAULT)
	local camera_position = obs.obs_properties_add_list(props, "camera_position", "Camera Position", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(camera_position, "Bottom Right", "bottom-right")
	obs.obs_property_list_add_string(camera_position, "Bottom Left", "bottom-left")
	obs.obs_property_list_add_string(camera_position, "Top Right", "top-right")
	obs.obs_property_list_add_string(camera_position, "Top Left", "top-left")
	obs.obs_property_list_add_string(camera_position, "Bottom Center", "center")
	obs.obs_properties_add_int_slider(props, "camera_size_pct", "Camera Size (%)", 8, 45, 1)
	obs.obs_properties_add_int_slider(props, "camera_margin", "Camera Margin", 0, 400, 1)
	obs.obs_properties_add_int(props, "area_crop_left", "Area Crop Left", 0, 7680, 1)
	obs.obs_properties_add_int(props, "area_crop_top", "Area Crop Top", 0, 4320, 1)
	obs.obs_properties_add_int(props, "area_crop_right", "Area Crop Right", 0, 7680, 1)
	obs.obs_properties_add_int(props, "area_crop_bottom", "Area Crop Bottom", 0, 4320, 1)

	obs.obs_properties_add_bool(props, "click_zoom_enabled", "Enable Click Zoom")
	obs.obs_properties_add_float_slider(props, "click_zoom_scale", "Auto Click Zoom Scale", 1.0, 5.0, 0.05)
	obs.obs_properties_add_float_slider(props, "typing_zoom_scale", "Typing Zoom Scale", 1.0, 5.0, 0.05)
	obs.obs_properties_add_int_slider(props, "click_reset_delay_ms", "Auto Click Reset Delay (ms)", 0, 6000, 50)
	obs.obs_properties_add_bool(props, "auto_focus_enabled", "Auto Focus after cursor dwell")
	obs.obs_properties_add_int_slider(props, "auto_focus_dwell_ms", "Auto Focus Dwell Time (ms)", 300, 2500, 50)
	obs.obs_properties_add_int_slider(props, "auto_focus_move_threshold", "Auto Focus Movement Tolerance", 2, 80, 1)
	obs.obs_properties_add_int_slider(props, "auto_focus_cooldown_ms", "Auto Focus Cooldown (ms)", 800, 8000, 100)
	obs.obs_properties_add_bool(props, "text_focus_enabled", "Auto Focus while typing")
	obs.obs_properties_add_int_slider(props, "text_focus_cooldown_ms", "Typing Focus Cooldown (ms)", 250, 3000, 50)
	obs.obs_properties_add_bool(props, "zoom_adds_chapter", "Zoom actions add recording chapters")
	local click_area_mode = obs.obs_properties_add_list(props, "click_area_mode", "Click Coordinate Area", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(click_area_mode, "Primary display", "primary")
	obs.obs_property_list_add_string(click_area_mode, "Virtual desktop", "virtual")
	obs.obs_property_list_add_string(click_area_mode, "Manual area", "manual")
	obs.obs_properties_add_int(props, "click_manual_x", "Manual Area X", -20000, 20000, 1)
	obs.obs_properties_add_int(props, "click_manual_y", "Manual Area Y", -20000, 20000, 1)
	obs.obs_properties_add_int(props, "click_manual_width", "Manual Area Width", 1, 7680, 1)
	obs.obs_properties_add_int(props, "click_manual_height", "Manual Area Height", 1, 4320, 1)

	obs.obs_properties_add_float_slider(props, "zoom_step", "Zoom Step", 1.01, 2.0, 0.01)
	obs.obs_properties_add_int_slider(props, "zoom_duration_ms", "Smooth Zoom Duration (ms)", 0, 1000, 10)
	obs.obs_properties_add_float_slider(props, "max_zoom", "Maximum Zoom", 1.0, 8.0, 0.05)
	obs.obs_properties_add_float_slider(props, "min_zoom", "Minimum Zoom", 0.05, 1.0, 0.05)
	obs.obs_properties_add_bool(props, "use_smooth_zoom", "Use Smooth Zoom")

	local mask_type = obs.obs_properties_add_list(props, "mask_type", "Mask Mode", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
	obs.obs_property_list_add_int(mask_type, "Alpha Mask (recommended)", 1)
	obs.obs_property_list_add_int(mask_type, "Color Channel Mask", 0)

	local corner_preset = obs.obs_properties_add_list(props, "corner_preset", "Corner Radius Preset", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(corner_preset, "Small", "small")
	obs.obs_property_list_add_string(corner_preset, "Medium", "medium")
	obs.obs_property_list_add_string(corner_preset, "Large", "large")

	obs.obs_properties_add_bool(props, "create_background", "Studio Look adds a rounded background card")
	obs.obs_properties_add_int(props, "card_width", "Card Source Width", 64, 7680, 1)
	obs.obs_properties_add_int(props, "card_height", "Card Source Height", 64, 4320, 1)
	obs.obs_properties_add_int(props, "card_margin", "Canvas Margin", 0, 1000, 1)
	obs.obs_properties_add_color(props, "card_color", "Card Color")
	obs.obs_properties_add_text(props, "card_source_name", "Card Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "rectangle_source_name", "Rectangle Source Name", obs.OBS_TEXT_DEFAULT)
	local canvas_preset = obs.obs_properties_add_list(props, "studio_canvas_preset", "Recording Aspect Preset", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(canvas_preset, "16:9 UHD - 3840 x 2160", "uhd_16_9")
	obs.obs_property_list_add_string(canvas_preset, "16:9 HD - 1920 x 1080", "hd_16_9")
	obs.obs_property_list_add_string(canvas_preset, "9:16 Vertical - 2160 x 3840", "portrait_9_16")
	obs.obs_property_list_add_string(canvas_preset, "3:4 Portrait - 2160 x 2880", "portrait_3_4")
	obs.obs_property_list_add_string(canvas_preset, "4:5 Portrait - 2160 x 2700", "portrait_4_5")
	obs.obs_property_list_add_string(canvas_preset, "1:1 Square - 2160 x 2160", "square_1_1")
	obs.obs_property_list_add_string(canvas_preset, "4:3 Classic - 2880 x 2160", "classic_4_3")
	obs.obs_property_list_add_string(canvas_preset, "Custom Size", "custom")
	obs.obs_properties_add_int(props, "studio_canvas_width", "Custom Canvas Width", 64, 7680, 1)
	obs.obs_properties_add_int(props, "studio_canvas_height", "Custom Canvas Height", 64, 7680, 1)
	obs.obs_properties_add_int_slider(props, "studio_profile_bitrate", "Recording Bitrate (Kbps)", 16000, 120000, 1000)
	obs.obs_properties_add_path(props, "studio_profile_path", "Recording Folder", obs.OBS_PATH_DIRECTORY, "", "")
	obs.obs_properties_add_bool(props, "studio_recording_starts_watcher", "Recording automatically starts cursor watcher")
	obs.obs_properties_add_bool(props, "studio_recording_adds_chapters", "Recording buttons add chapters")
	obs.obs_properties_add_bool(props, "studio_auto_apply_4k_profile", "Auto apply recording aspect preset")
	obs.obs_properties_add_bool(props, "studio_auto_setup_on_load", "Auto setup current scene when OBS opens")
	obs.obs_properties_add_bool(props, "studio_auto_start_zoom_on_load", "Auto start click zoom when OBS opens")
	obs.obs_properties_add_bool(props, "studio_exclude_taskbar", "Exclude Windows taskbar from screen capture")

	return props
end

function script_defaults(settings)
	obs.obs_data_set_default_double(settings, "zoom_step", 1.18)
	obs.obs_data_set_default_int(settings, "zoom_duration_ms", 620)
	obs.obs_data_set_default_double(settings, "max_zoom", 3.0)
	obs.obs_data_set_default_double(settings, "min_zoom", 0.25)
	obs.obs_data_set_default_bool(settings, "use_smooth_zoom", true)
	obs.obs_data_set_default_int(settings, "mask_type", 1)
	obs.obs_data_set_default_string(settings, "corner_preset", "large")
	obs.obs_data_set_default_bool(settings, "create_background", true)
	obs.obs_data_set_default_int(settings, "card_width", 1728)
	obs.obs_data_set_default_int(settings, "card_height", 972)
	obs.obs_data_set_default_int(settings, "card_margin", 180)
	obs.obs_data_set_default_int(settings, "card_color", 0x1F232A)
	obs.obs_data_set_default_string(settings, "card_source_name", "Screen Studio Card")
	obs.obs_data_set_default_string(settings, "rectangle_source_name", "Rounded Rectangle")
	obs.obs_data_set_default_bool(settings, "visual_layer_enabled", true)
	obs.obs_data_set_default_string(settings, "visual_layer_style", "aurora")
	obs.obs_data_set_default_bool(settings, "visual_layer_card", true)
	obs.obs_data_set_default_bool(settings, "visual_layer_cursor", true)
	obs.obs_data_set_default_double(settings, "visual_layer_cursor_scale", 1.35)
	obs.obs_data_set_default_int(settings, "visual_layer_idle_ms", 0)
	obs.obs_data_set_default_double(settings, "visual_layer_smoothing", 0.20)
	obs.obs_data_set_default_bool(settings, "visual_layer_touch_cursor", false)
	obs.obs_data_set_default_bool(settings, "visual_keystrokes", true)
	obs.obs_data_set_default_int(settings, "visual_keystroke_hold_ms", 1200)
	obs.obs_data_set_default_string(settings, "visual_keystroke_position", "bottom")
	obs.obs_data_set_default_bool(settings, "visual_cursor_rotate", true)
	obs.obs_data_set_default_double(settings, "visual_cursor_shake_threshold", 1.2)
	obs.obs_data_set_default_string(settings, "visual_cursor_color", "#FFFFFF")
	obs.obs_data_set_default_string(settings, "visual_cursor_accent", "#2DD4BF")
	obs.obs_data_set_default_string(settings, "visual_click_color", "#FFFFFF")
	obs.obs_data_set_default_double(settings, "visual_card_inset", 8.5)
	obs.obs_data_set_default_int(settings, "visual_card_radius", 34)
	obs.obs_data_set_default_int(settings, "visual_card_opacity", 62)
	obs.obs_data_set_default_int(settings, "visual_shadow_strength", 34)
	obs.obs_data_set_default_bool(settings, "visual_bg_solid", true)
	obs.obs_data_set_default_string(settings, "visual_bg_color_a", "#CBD198")
	obs.obs_data_set_default_string(settings, "visual_bg_color_b", "#CBD198")
	obs.obs_data_set_default_string(settings, "visual_bg_color_c", "#CBD198")
	obs.obs_data_set_default_string(settings, "visual_bg_image", "")
	obs.obs_data_set_default_string(settings, "visual_layer_source_name", VISUAL_LAYER_SOURCE_NAME)
	obs.obs_data_set_default_string(settings, "frame_layer_source_name", FRAME_LAYER_SOURCE_NAME)
	obs.obs_data_set_default_string(settings, "cursor_layer_source_name", CURSOR_LAYER_SOURCE_NAME)
	obs.obs_data_set_default_string(settings, "zoom_target_source_name", "Screen Capture")
	obs.obs_data_set_default_string(settings, "capture_source_name", "Screen Capture")
	obs.obs_data_set_default_string(settings, "window_source_name", "Window Capture")
	obs.obs_data_set_default_string(settings, "area_source_name", "Area Capture")
	obs.obs_data_set_default_bool(settings, "studio_use_dedicated_scene", false)
	obs.obs_data_set_default_string(settings, "studio_scene_name", STUDIO_SCENE_NAME)
	obs.obs_data_set_default_bool(settings, "camera_enabled", false)
	obs.obs_data_set_default_string(settings, "camera_source_name", "Camera")
	obs.obs_data_set_default_string(settings, "camera_placeholder_source_name", CAMERA_PLACEHOLDER_SOURCE_NAME)
	obs.obs_data_set_default_string(settings, "mic_source_name", "Microphone")
	obs.obs_data_set_default_string(settings, "system_audio_source_name", "System Audio")
	obs.obs_data_set_default_string(settings, "camera_position", "bottom-right")
	obs.obs_data_set_default_int(settings, "camera_size_pct", 22)
	obs.obs_data_set_default_int(settings, "camera_margin", 80)
	obs.obs_data_set_default_int(settings, "area_crop_left", 0)
	obs.obs_data_set_default_int(settings, "area_crop_top", 0)
	obs.obs_data_set_default_int(settings, "area_crop_right", 0)
	obs.obs_data_set_default_int(settings, "area_crop_bottom", 0)
	obs.obs_data_set_default_bool(settings, "click_zoom_enabled", true)
	obs.obs_data_set_default_double(settings, "click_zoom_scale", 2.0)
	obs.obs_data_set_default_double(settings, "typing_zoom_scale", 2.6)
	obs.obs_data_set_default_int(settings, "click_reset_delay_ms", 5000)
	obs.obs_data_set_default_bool(settings, "auto_focus_enabled", false)
	obs.obs_data_set_default_int(settings, "auto_focus_dwell_ms", 900)
	obs.obs_data_set_default_int(settings, "auto_focus_move_threshold", 18)
	obs.obs_data_set_default_int(settings, "auto_focus_cooldown_ms", 2400)
	obs.obs_data_set_default_bool(settings, "text_focus_enabled", true)
	obs.obs_data_set_default_int(settings, "text_focus_cooldown_ms", 900)
	obs.obs_data_set_default_bool(settings, "zoom_adds_chapter", true)
	obs.obs_data_set_default_string(settings, "click_area_mode", "primary")
	obs.obs_data_set_default_int(settings, "click_manual_x", 0)
	obs.obs_data_set_default_int(settings, "click_manual_y", 0)
	obs.obs_data_set_default_int(settings, "click_manual_width", 1920)
	obs.obs_data_set_default_int(settings, "click_manual_height", 1080)
	obs.obs_data_set_default_int(settings, "studio_profile_bitrate", 90000)
	obs.obs_data_set_default_string(settings, "studio_profile_path", "")
	obs.obs_data_set_default_string(settings, "studio_canvas_preset", "portrait_3_4")
	obs.obs_data_set_default_int(settings, "studio_canvas_width", 2160)
	obs.obs_data_set_default_int(settings, "studio_canvas_height", 2880)
	obs.obs_data_set_default_bool(settings, "studio_recording_starts_watcher", true)
	obs.obs_data_set_default_bool(settings, "studio_recording_adds_chapters", true)
	obs.obs_data_set_default_bool(settings, "studio_auto_apply_4k_profile", true)
	obs.obs_data_set_default_bool(settings, "studio_auto_setup_on_load", true)
	obs.obs_data_set_default_bool(settings, "studio_auto_start_zoom_on_load", true)
	obs.obs_data_set_default_bool(settings, "studio_exclude_taskbar", true)
	obs.obs_data_set_default_string(settings, "quick_help", "Select a source in preview first. Hotkeys are configured in Settings > Hotkeys after this script is loaded.")
end

function script_update(settings)
	settings_state.zoom_step = obs.obs_data_get_double(settings, "zoom_step")
	settings_state.zoom_duration_ms = obs.obs_data_get_int(settings, "zoom_duration_ms")
	if settings_state.zoom_duration_ms <= 0 then
		settings_state.zoom_duration_ms = 620
	end
	settings_state.max_zoom = obs.obs_data_get_double(settings, "max_zoom")
	settings_state.min_zoom = obs.obs_data_get_double(settings, "min_zoom")
	settings_state.use_smooth_zoom = obs.obs_data_get_bool(settings, "use_smooth_zoom")
	settings_state.mask_type = obs.obs_data_get_int(settings, "mask_type")
	settings_state.corner_preset = obs.obs_data_get_string(settings, "corner_preset")
	settings_state.create_background = obs.obs_data_get_bool(settings, "create_background")
	settings_state.card_width = obs.obs_data_get_int(settings, "card_width")
	settings_state.card_height = obs.obs_data_get_int(settings, "card_height")
	settings_state.card_margin = obs.obs_data_get_int(settings, "card_margin")
	settings_state.card_color = obs.obs_data_get_int(settings, "card_color")
	settings_state.card_source_name = obs.obs_data_get_string(settings, "card_source_name")
	settings_state.rectangle_source_name = obs.obs_data_get_string(settings, "rectangle_source_name")
	settings_state.visual_layer_enabled = obs.obs_data_get_bool(settings, "visual_layer_enabled")
	settings_state.visual_layer_style = obs.obs_data_get_string(settings, "visual_layer_style")
	settings_state.visual_layer_card = obs.obs_data_get_bool(settings, "visual_layer_card")
	settings_state.visual_layer_cursor = obs.obs_data_get_bool(settings, "visual_layer_cursor")
	settings_state.visual_layer_cursor_scale = obs.obs_data_get_double(settings, "visual_layer_cursor_scale")
	settings_state.visual_layer_idle_ms = obs.obs_data_get_int(settings, "visual_layer_idle_ms")
	settings_state.visual_layer_smoothing = obs.obs_data_get_double(settings, "visual_layer_smoothing")
	settings_state.visual_layer_touch_cursor = obs.obs_data_get_bool(settings, "visual_layer_touch_cursor")
	settings_state.visual_keystrokes = obs.obs_data_get_bool(settings, "visual_keystrokes")
	settings_state.visual_keystroke_hold_ms = obs.obs_data_get_int(settings, "visual_keystroke_hold_ms")
	settings_state.visual_keystroke_position = obs.obs_data_get_string(settings, "visual_keystroke_position")
	settings_state.visual_cursor_rotate = obs.obs_data_get_bool(settings, "visual_cursor_rotate")
	settings_state.visual_cursor_shake_threshold = obs.obs_data_get_double(settings, "visual_cursor_shake_threshold")
	settings_state.visual_cursor_color = obs.obs_data_get_string(settings, "visual_cursor_color")
	settings_state.visual_cursor_accent = obs.obs_data_get_string(settings, "visual_cursor_accent")
	settings_state.visual_click_color = obs.obs_data_get_string(settings, "visual_click_color")
	settings_state.visual_card_inset = obs.obs_data_get_double(settings, "visual_card_inset")
	settings_state.visual_card_radius = obs.obs_data_get_int(settings, "visual_card_radius")
	settings_state.visual_card_opacity = obs.obs_data_get_int(settings, "visual_card_opacity")
	settings_state.visual_shadow_strength = obs.obs_data_get_int(settings, "visual_shadow_strength")
	settings_state.visual_bg_solid = obs.obs_data_get_bool(settings, "visual_bg_solid")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "visual_bg_solid") then
		settings_state.visual_bg_solid = true
	end
	settings_state.visual_bg_color_a = obs.obs_data_get_string(settings, "visual_bg_color_a")
	settings_state.visual_bg_color_b = obs.obs_data_get_string(settings, "visual_bg_color_b")
	settings_state.visual_bg_color_c = obs.obs_data_get_string(settings, "visual_bg_color_c")
	if settings_state.visual_bg_color_a == nil or settings_state.visual_bg_color_a == "" then
		settings_state.visual_bg_color_a = "#CBD198"
	end
	if settings_state.visual_bg_color_b == nil or settings_state.visual_bg_color_b == "" then
		settings_state.visual_bg_color_b = settings_state.visual_bg_color_a
	end
	if settings_state.visual_bg_color_c == nil or settings_state.visual_bg_color_c == "" then
		settings_state.visual_bg_color_c = settings_state.visual_bg_color_a
	end
	settings_state.visual_bg_image = obs.obs_data_get_string(settings, "visual_bg_image")
	settings_state.visual_layer_source_name = obs.obs_data_get_string(settings, "visual_layer_source_name")
	settings_state.frame_layer_source_name = obs.obs_data_get_string(settings, "frame_layer_source_name")
	if settings_state.frame_layer_source_name == nil or settings_state.frame_layer_source_name == "" then
		settings_state.frame_layer_source_name = FRAME_LAYER_SOURCE_NAME
	end
	settings_state.cursor_layer_source_name = obs.obs_data_get_string(settings, "cursor_layer_source_name")
	settings_state.zoom_target_source_name = obs.obs_data_get_string(settings, "zoom_target_source_name")
	settings_state.capture_source_name = obs.obs_data_get_string(settings, "capture_source_name")
	settings_state.window_source_name = obs.obs_data_get_string(settings, "window_source_name")
	settings_state.area_source_name = obs.obs_data_get_string(settings, "area_source_name")
	settings_state.studio_use_dedicated_scene = obs.obs_data_get_bool(settings, "studio_use_dedicated_scene")
	settings_state.studio_scene_name = obs.obs_data_get_string(settings, "studio_scene_name")
	settings_state.camera_enabled = obs.obs_data_get_bool(settings, "camera_enabled")
	settings_state.camera_source_name = obs.obs_data_get_string(settings, "camera_source_name")
	settings_state.camera_placeholder_source_name = obs.obs_data_get_string(settings, "camera_placeholder_source_name")
	settings_state.mic_source_name = obs.obs_data_get_string(settings, "mic_source_name")
	settings_state.system_audio_source_name = obs.obs_data_get_string(settings, "system_audio_source_name")
	settings_state.camera_position = obs.obs_data_get_string(settings, "camera_position")
	settings_state.camera_size_pct = obs.obs_data_get_int(settings, "camera_size_pct")
	settings_state.camera_margin = obs.obs_data_get_int(settings, "camera_margin")
	settings_state.area_crop_left = obs.obs_data_get_int(settings, "area_crop_left")
	settings_state.area_crop_top = obs.obs_data_get_int(settings, "area_crop_top")
	settings_state.area_crop_right = obs.obs_data_get_int(settings, "area_crop_right")
	settings_state.area_crop_bottom = obs.obs_data_get_int(settings, "area_crop_bottom")
	settings_state.click_zoom_enabled = obs.obs_data_get_bool(settings, "click_zoom_enabled")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "click_zoom_enabled") then
		settings_state.click_zoom_enabled = true
	end
	settings_state.click_zoom_scale = obs.obs_data_get_double(settings, "click_zoom_scale")
	if settings_state.click_zoom_scale <= 0 then
		settings_state.click_zoom_scale = 2.0
	elseif math.abs(settings_state.click_zoom_scale - 1.5) < 0.001 or math.abs(settings_state.click_zoom_scale - 1.8) < 0.001 then
		settings_state.click_zoom_scale = 2.0
		obs.obs_data_set_double(settings, "click_zoom_scale", settings_state.click_zoom_scale)
	end
	settings_state.typing_zoom_scale = obs.obs_data_get_double(settings, "typing_zoom_scale")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "typing_zoom_scale") then
		settings_state.typing_zoom_scale = 2.6
		obs.obs_data_set_double(settings, "typing_zoom_scale", settings_state.typing_zoom_scale)
	elseif settings_state.typing_zoom_scale <= 0 then
		settings_state.typing_zoom_scale = 2.6
		obs.obs_data_set_double(settings, "typing_zoom_scale", settings_state.typing_zoom_scale)
	end
	settings_state.click_reset_delay_ms = obs.obs_data_get_int(settings, "click_reset_delay_ms")
	settings_state.auto_focus_enabled = obs.obs_data_get_bool(settings, "auto_focus_enabled")
	settings_state.auto_focus_dwell_ms = obs.obs_data_get_int(settings, "auto_focus_dwell_ms")
	settings_state.auto_focus_move_threshold = obs.obs_data_get_int(settings, "auto_focus_move_threshold")
	settings_state.auto_focus_cooldown_ms = obs.obs_data_get_int(settings, "auto_focus_cooldown_ms")
	settings_state.text_focus_enabled = obs.obs_data_get_bool(settings, "text_focus_enabled")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "text_focus_enabled") then
		settings_state.text_focus_enabled = true
		obs.obs_data_set_bool(settings, "text_focus_enabled", settings_state.text_focus_enabled)
	end
	settings_state.text_focus_cooldown_ms = obs.obs_data_get_int(settings, "text_focus_cooldown_ms")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "text_focus_cooldown_ms") then
		settings_state.text_focus_cooldown_ms = 700
		obs.obs_data_set_int(settings, "text_focus_cooldown_ms", settings_state.text_focus_cooldown_ms)
	elseif settings_state.text_focus_cooldown_ms <= 0 then
		settings_state.text_focus_cooldown_ms = 700
		obs.obs_data_set_int(settings, "text_focus_cooldown_ms", settings_state.text_focus_cooldown_ms)
	end
	settings_state.zoom_adds_chapter = obs.obs_data_get_bool(settings, "zoom_adds_chapter")
	settings_state.click_area_mode = obs.obs_data_get_string(settings, "click_area_mode")
	settings_state.click_manual_x = obs.obs_data_get_int(settings, "click_manual_x")
	settings_state.click_manual_y = obs.obs_data_get_int(settings, "click_manual_y")
	settings_state.click_manual_width = obs.obs_data_get_int(settings, "click_manual_width")
	settings_state.click_manual_height = obs.obs_data_get_int(settings, "click_manual_height")
	settings_state.studio_profile_bitrate = obs.obs_data_get_int(settings, "studio_profile_bitrate")
	if settings_state.studio_profile_bitrate <= 0 then
		settings_state.studio_profile_bitrate = 90000
		obs.obs_data_set_int(settings, "studio_profile_bitrate", settings_state.studio_profile_bitrate)
	elseif settings_state.studio_profile_bitrate <= 60000 then
		settings_state.studio_profile_bitrate = 90000
		obs.obs_data_set_int(settings, "studio_profile_bitrate", settings_state.studio_profile_bitrate)
	end
	settings_state.studio_profile_path = obs.obs_data_get_string(settings, "studio_profile_path")
	settings_state.studio_canvas_preset = obs.obs_data_get_string(settings, "studio_canvas_preset")
	settings_state.studio_canvas_width = obs.obs_data_get_int(settings, "studio_canvas_width")
	settings_state.studio_canvas_height = obs.obs_data_get_int(settings, "studio_canvas_height")
	settings_state.studio_recording_starts_watcher = obs.obs_data_get_bool(settings, "studio_recording_starts_watcher")
	settings_state.studio_recording_adds_chapters = obs.obs_data_get_bool(settings, "studio_recording_adds_chapters")
	settings_state.studio_auto_apply_4k_profile = obs.obs_data_get_bool(settings, "studio_auto_apply_4k_profile")
	settings_state.studio_auto_setup_on_load = obs.obs_data_get_bool(settings, "studio_auto_setup_on_load")
	settings_state.studio_auto_start_zoom_on_load = obs.obs_data_get_bool(settings, "studio_auto_start_zoom_on_load")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "studio_auto_start_zoom_on_load") then
		settings_state.studio_auto_start_zoom_on_load = true
	end
	settings_state.studio_exclude_taskbar = obs.obs_data_get_bool(settings, "studio_exclude_taskbar")
	if obs.obs_data_has_user_value ~= nil and not obs.obs_data_has_user_value(settings, "studio_exclude_taskbar") then
		settings_state.studio_exclude_taskbar = true
		obs.obs_data_set_bool(settings, "studio_exclude_taskbar", settings_state.studio_exclude_taskbar)
	end
end

function script_load(settings)
	HOTKEY_ZOOM_IN = obs.obs_hotkey_register_frontend("screen_studio_lite.zoom_in", "Screen Studio Lite: Zoom In Selected Source", zoom_in_pressed)
	HOTKEY_ZOOM_OUT = obs.obs_hotkey_register_frontend("screen_studio_lite.zoom_out", "Screen Studio Lite: Zoom Out Selected Source", zoom_out_pressed)
	HOTKEY_RESET = obs.obs_hotkey_register_frontend("screen_studio_lite.reset", "Screen Studio Lite: Reset Selected Source", reset_pressed)
	HOTKEY_ROUND = obs.obs_hotkey_register_frontend("screen_studio_lite.round", "Screen Studio Lite: Apply Rounded Corners", round_pressed)
	HOTKEY_ZOOM_CURSOR = obs.obs_hotkey_register_frontend("screen_studio_lite.zoom_cursor", "Screen Studio Lite: Zoom To Current Cursor", zoom_cursor_pressed)
	HOTKEY_START_RECORDING = obs.obs_hotkey_register_frontend("screen_studio_lite.start_recording", "Screen Studio Lite: Start Studio Recording", start_recording_pressed)
	HOTKEY_STOP_RECORDING = obs.obs_hotkey_register_frontend("screen_studio_lite.stop_recording", "Screen Studio Lite: Stop Studio Recording", stop_recording_pressed)
	HOTKEY_MARK_CHAPTER = obs.obs_hotkey_register_frontend("screen_studio_lite.mark_chapter", "Screen Studio Lite: Add Chapter Marker", mark_chapter_pressed)

	local hotkey_save_array = obs.obs_data_get_array(settings, "zoom_in_hotkey")
	obs.obs_hotkey_load(HOTKEY_ZOOM_IN, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "zoom_out_hotkey")
	obs.obs_hotkey_load(HOTKEY_ZOOM_OUT, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(HOTKEY_RESET, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "round_hotkey")
	obs.obs_hotkey_load(HOTKEY_ROUND, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "zoom_cursor_hotkey")
	obs.obs_hotkey_load(HOTKEY_ZOOM_CURSOR, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "start_recording_hotkey")
	obs.obs_hotkey_load(HOTKEY_START_RECORDING, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "stop_recording_hotkey")
	obs.obs_hotkey_load(HOTKEY_STOP_RECORDING, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_data_get_array(settings, "mark_chapter_hotkey")
	obs.obs_hotkey_load(HOTKEY_MARK_CHAPTER, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	obs.timer_add(recording_tick, 500)
	obs.timer_add(auto_setup_tick, 1200)
	obs.timer_add(color_background_sync_tick, 1000)
end

function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(HOTKEY_ZOOM_IN)
	obs.obs_data_set_array(settings, "zoom_in_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_ZOOM_OUT)
	obs.obs_data_set_array(settings, "zoom_out_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_RESET)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_ROUND)
	obs.obs_data_set_array(settings, "round_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_ZOOM_CURSOR)
	obs.obs_data_set_array(settings, "zoom_cursor_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_START_RECORDING)
	obs.obs_data_set_array(settings, "start_recording_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_STOP_RECORDING)
	obs.obs_data_set_array(settings, "stop_recording_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)

	hotkey_save_array = obs.obs_hotkey_save(HOTKEY_MARK_CHAPTER)
	obs.obs_data_set_array(settings, "mark_chapter_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

function script_unload()
	obs.timer_remove(animation_tick)
	obs.timer_remove(click_poll_tick)
	obs.timer_remove(click_reset_tick)
	obs.timer_remove(recording_tick)
	obs.timer_remove(auto_setup_tick)
	obs.timer_remove(plain_color_cleanup_tick)
	obs.timer_remove(color_background_sync_tick)
	obs.timer_remove(restore_frame_layer_tick)
	if click_zoom_running then
		stop_click_zoom_watcher()
	end

	for id, anim in pairs(animations) do
		if anim.item ~= nil then
			obs.obs_sceneitem_release(anim.item)
		end
		animations[id] = nil
	end
end


