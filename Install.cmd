@echo off
setlocal
title Codex Model Hotkeys Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-Latest.ps1"
if errorlevel 1 (
  echo.
  echo Installation failed. See the error above.
  pause
  exit /b 1
)
endlocal
