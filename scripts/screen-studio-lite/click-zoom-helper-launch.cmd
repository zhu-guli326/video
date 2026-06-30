@echo off
setlocal
set "DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%DIR%click-zoom-helper.ps1" -StatePath "%DIR%click-state.txt" -StopPath "%DIR%click-stop.flag" >> "%DIR%click-zoom-helper.out.log" 2>> "%DIR%click-zoom-helper.err.log"
exit
