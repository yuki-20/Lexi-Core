@echo off
setlocal enabledelayedexpansion
title LexiCore

cd /d "%~dp0"
set "PYTHON_EXE=%~dp0.venv\Scripts\python.exe"
set "UI_EXE=%~dp0ui\lexicore_ui.exe"

if not exist "%PYTHON_EXE%" (
  echo LexiCore runtime is missing at "%PYTHON_EXE%".
  echo Reinstall LexiCore to recreate the isolated Python environment.
  pause
  exit /b 1
)

if not exist "%UI_EXE%" (
  echo LexiCore UI is missing at "%UI_EXE%".
  echo Reinstall LexiCore to restore the bundled Windows app.
  pause
  exit /b 1
)

if not exist "%~dp0data" mkdir "%~dp0data" >nul 2>&1
set "PYTHONUTF8=1"

curl -fsS -o nul http://127.0.0.1:8741/api/stats >nul 2>&1
if errorlevel 1 (
  echo Starting backend engine...
  start "" /b cmd /c "\"%PYTHON_EXE%\" -m engine.main 1>>\"%~dp0data\launcher-backend.out.log\" 2>>\"%~dp0data\launcher-backend.err.log\""
)

echo Waiting for engine to initialize...
set "READY="
for /L %%i in (1,1,30) do (
  timeout /t 1 /nobreak >nul
  curl -fsS -o nul http://127.0.0.1:8741/api/stats >nul 2>&1
  if not errorlevel 1 set "READY=1"
  if defined READY goto launch
)

echo Backend did not become ready within 30 seconds.
pause
exit /b 1

:launch
echo Launching LexiCore...
start "" "%UI_EXE%"
endlocal
