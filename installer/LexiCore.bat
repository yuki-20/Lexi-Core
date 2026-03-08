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

:: Wait for backend to start
echo Waiting for engine to initialize...
timeout /t 4 /nobreak >nul

:: Launch the Flutter UI (actual binary name is lexicore_ui.exe)
echo Launching LexiCore...
start "" "%~dp0ui\lexicore_ui.exe"
