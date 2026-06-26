# Screen Studio Lite for OBS

Screen Studio Lite is a safe script-only workflow for making OBS recordings look closer to Screen Studio product demos. It does not modify `obs64.exe` or OBS DLLs.

## What It Adds

- Auto zoom: watches mouse clicks and cursor dwell, then smoothly zooms the screen/window/area source toward the focus point and optionally resets.
- Cursor polish: a Browser Source overlay draws a smoothed, enlarged cursor, click rings, optional touch cursor, and hides the cursor after idle time. Turn off native OBS cursor capture on screen/window sources for best results.
- Keystroke overlay: shows shortcut combinations in a polished floating capsule.
- Pretty background: a gradient background and glassy product-card layer for product demo framing.
- Full screen/window/area recording helpers: buttons create OBS screen capture, window capture, or cropped area capture sources.
- Camera and audio helpers: buttons add a camera overlay, default microphone, and default system audio.
- Editing/export workflow: hotkeys support zoom choreography while recording; aspect presets set high-quality 16:9, 3:4, 9:16, square, or custom output for post-editing or final export.
- Timeline notes: recording and zoom events are written to `studio-timeline.md` so you can review focus moments after recording.
- Studio Editor: a local HTML editor shows zoom events as Screen Studio style timeline blocks.
- Rounded rectangles: apply rounded corners to selected sources or add full-canvas rounded rectangles/cards.

## Install

1. Open OBS.
2. Go to `Tools > Scripts`.
3. Click `+`.
4. Load:

   `%LOCALAPPDATA%\ScreenStudioLite\screen-studio-lite.lua`

5. Select a source in the preview canvas, then use the script buttons.

## Fast Setup

Use `Start Studio Recording` for the closest Screen Studio style path. It will build the scene, refresh the background/cursor layers, start the cursor watcher, and start OBS recording.

By default, the script uses a dedicated scene named `Screen Studio Recording`. This keeps the recording layout isolated from your normal OBS scenes and makes the workflow feel closer to Screen Studio. If OBS does not switch the live scene automatically in your build, switch to `Screen Studio Recording` once after setup.

Use `Create Full Studio Setup` if you only want to prepare the scene without recording. It adds:

- `Screen Studio Lite - Background`
- `Screen Studio Lite - Cursor`
- `Screen Capture`
- `Camera`
- `Microphone`
- `System Audio`

The background layer should stay at the bottom, your capture source should sit above it, and the cursor layer should stay at the top. If your native OBS capture source also shows the cursor, disable `Capture Cursor` in that source so only the polished cursor overlay appears.

## Auto Zoom

1. Click `Start Auto Click Zoom + Cursor Watcher`, or use `Start Studio Recording`.
2. Click anywhere on the captured screen. The screen/window/area source zooms toward that click and resets after the configured delay.
3. Pause the cursor over an area to trigger dwell auto-focus when enabled.

Use `Zoom To Current Cursor` for a Screen Studio style manual highlight when you want to zoom without clicking.

Auto Zoom controls the source named in `Auto Zoom Target Source Name`. The helper buttons set this automatically:

- `Add Full Screen Capture` sets it to `Screen Capture`.
- `Add Window Capture` sets it to `Window Capture`.
- `Add Area Capture from Crop Values` sets it to `Area Capture`.
- `Use Selected Source For Auto Zoom` sets it to whichever source is currently selected.
- `Test 1.8x Zoom Target` verifies that the chosen source visibly scales before you test click zoom.

Settings:

- `Auto Zoom Target Source Name`: the exact OBS source that should be zoomed.
- `Auto Click Zoom Scale`: default is 1.8x for a visible Screen Studio style focus zoom.
- `Auto Click Reset Delay`: how long before it animates back.
- `Auto Focus after cursor dwell`: automatically zoom after the cursor stays in one area.
- `Auto Focus Dwell Time`: how long the cursor must pause before focus zoom.
- `Auto Focus Cooldown`: minimum time between dwell zooms.
- `Zoom actions add recording chapters`: add chapter markers on click/dwell/manual zoom for faster review.
- `Click Coordinate Area`: use `Primary display`, `Virtual desktop`, or manual coordinates for multi-monitor/cropped workflows.

If no source is selected, the script automatically targets `Screen Capture`, `Window Capture`, or `Area Capture`.

## Area Recording

Set these values, then click `Add Area Capture from Crop Values`:

- `Area Crop Left`
- `Area Crop Top`
- `Area Crop Right`
- `Area Crop Bottom`

This creates a normal OBS display capture and applies scene-item crop values. For precise region capture, adjust the crop values in OBS transform controls after the source is created.

## Recording Aspect Presets

Choose `Recording Aspect Preset`, then click `Apply Recording Aspect Preset` to set the OBS canvas/output and generated export script.

- 16:9 UHD: 3840 x 2160
- 16:9 HD: 1920 x 1080
- 9:16 Vertical: 2160 x 3840
- 3:4 Portrait: 2160 x 2880
- 4:5 Portrait: 2160 x 2700
- 1:1 Square: 2160 x 2160
- 4:3 Classic: 2880 x 2160
- Custom Size: use `Custom Canvas Width` and `Custom Canvas Height`
- FPS: 60
- Recording format: hybrid MP4
- Bitrate: controlled by `Recording Bitrate (Kbps)`

If OBS settings still show the old canvas, restart OBS once. For trimming and final polish, import the recorded file into your editor of choice, cut dead time, and export at the same aspect preset.

## Look And Feel

The script exposes Screen Studio style appearance controls:

- Background style, three custom background colors, or a custom background image.
- Card inset, radius, opacity, and shadow strength.
- Cursor size, smoothing, shake reduction, idle hiding, movement rotation, color, accent color, click-ring color, and touch mode.
- Keystroke display, hold time, and top/bottom placement.
- Camera position, size, margin, and rounded mask.

After changing these settings, click `Add / Refresh Background + Cursor Layers`.

## Recording Controls

- `Start Studio Recording`: prepare scene, start watcher, start recording.
- `Stop Studio Recording`: add an end marker and stop recording.
- `Pause / Resume Recording`: toggles OBS recording pause.
- `Add Chapter Marker`: adds a chapter marker to supported recording formats.
- `Split Recording File`: starts a new recording file when OBS supports file splitting.
- `Open Studio Editor`: opens the local timeline viewer after recording.

## Timeline Notes

Every `Start Studio Recording` creates:

`%LOCALAPPDATA%\ScreenStudioLite\screen-studio-lite\studio-timeline.md`

It also writes:

`%LOCALAPPDATA%\ScreenStudioLite\screen-studio-lite\studio-timeline.json`

The files record start/stop, pause/resume, split, chapter, click zoom, dwell zoom, and cursor zoom events with timestamps, coordinates, and zoom scale. Use them as a lightweight Screen Studio style edit list after recording.

Click `Open Studio Editor` to view:

`%LOCALAPPDATA%\ScreenStudioLite\screen-studio-lite\studio-editor.html`

The editor shows zoom events as purple timeline blocks and lets you inspect each event's offset, coordinates, zoom scale, and raw JSON.

## Hotkeys

After loading the script, open `Settings > Hotkeys` and search for `Screen Studio Lite`.

- `Start Studio Recording`
- `Stop Studio Recording`
- `Zoom To Current Cursor`
- `Add Chapter Marker`
- `Zoom In Selected Source`
- `Zoom Out Selected Source`
- `Reset Selected Source`
- `Apply Rounded Corners`

## Notes

- Rounded corners use a stable top frame layer named `Screen Studio Lite - Frame` plus masks for individual source rounding.
- The included masks are white rounded rectangles with transparent outside edges in small, medium, large, and dynamic presets.
- If individual source rounded corners do not appear, refresh the background/frame layers first, then switch `Mask Mode` between `Alpha Mask` and `Color Channel Mask`.
- The cursor and auto-click watcher are powered by `click-zoom-helper.ps1`; stopping the watcher writes a stop flag and exits the helper.
