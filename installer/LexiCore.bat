@echo off
title LexiCore
echo.
echo  ╔═══════════════════════════════════════╗
echo  ║         LexiCore v5.5 Launcher        ║
echo  ╚═══════════════════════════════════════╝
echo.

:: Start the Python backend
cd /d "%~dp0"
echo Starting backend engine...
start /b "" python -m engine.main >nul 2>&1

:: Wait for backend — longer on first run (auto-build dictionary)
echo Waiting for engine to initialize...
set READY=0
for /L %%i in (1,1,15) do (
    timeout /t 1 /nobreak >nul
    curl -s -o nul -w "%%{http_code}" http://127.0.0.1:8741/api/stats >nul 2>&1 && set READY=1
    if !READY! equ 1 goto :launch
)
:launch

:: Launch the Flutter UI (actual binary name is lexicore_ui.exe)
echo Launching LexiCore...
start "" "%~dp0ui\lexicore_ui.exe"
