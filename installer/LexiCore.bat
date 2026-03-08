@echo off
title LexiCore
echo Starting LexiCore Engine...

:: Start the Python backend
cd /d "%~dp0"
start /b "" python -m engine.main >nul 2>&1

:: Wait for backend to start
echo Waiting for backend...
timeout /t 4 /nobreak >nul

:: Launch the Flutter app
start "" "%~dp0ui\LexiCore.exe"
