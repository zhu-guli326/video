# Screen Studio Lite for OBS

Screen Studio Lite is a Windows OBS Lua script package for polished screen recordings:
portrait 3:4 recording, click zoom, typing zoom, rounded screen framing, cursor visuals,
background cards, and high-quality OBS recording defaults.

## Features

- 3:4 portrait canvas preset: `2160 x 2880`
- High quality recording profile: 60 FPS, Lanczos scaling, high bitrate NVENC defaults
- Click zoom: defaults to `2.0x`
- Typing zoom: defaults to `2.6x` and follows the text caret
- Vertical-aware zoom panning so the bottom of the screen is not cropped out
- Cursor overlay, click feedback, rounded screen mask, and solid background card
- Installer enables `HideOBSWindowsFromCapture=true` to avoid OBS-in-OBS recursion

## Install

1. Close OBS.
2. Download or clone this repository.
3. Double-click `install-windows.cmd`.
4. Open OBS normally.
5. Go to `Tools > Scripts`.
6. If `screen-studio-lite.lua` is not listed, add:
   `%APPDATA%\obs-studio\scripts\screen-studio-lite.lua`
7. In the script panel, click `Create Full Studio Setup`.

## Recommended Use

- Choose normal startup if OBS asks about safe mode. Safe mode disables scripts.
- Keep OBS minimized or on another screen while recording.
- Use the script settings to tune:
  - `Auto Click Zoom Scale`
  - `Typing Zoom Scale`
  - `Auto Click Reset Delay`
  - `Smooth Zoom Duration`
  - `Recording Aspect Preset`

## Uninstall

Close OBS, then double-click `uninstall-windows.cmd`.

## Notes

The installer copies script files into the OBS scripts folder. It does not overwrite your
OBS scene collection.
