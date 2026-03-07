---
description: Auto-start the LexiCore backend and Flutter app with a single command
---

# Auto-Run LexiCore

This workflow auto-starts both the Python backend and the Flutter desktop app.

**IMPORTANT:** When restarting the backend, ALWAYS just terminate the old process and force start a new one. Do NOT wait for graceful shutdown — just kill and restart instantly.

## Steps

// turbo-all

1. Force-kill any existing backend on port 8741 (don't wait, just terminate):
```powershell
Get-NetTCPConnection -LocalPort 8741 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
```

2. Start the backend (run as background command, wait max 6s for startup output):
```powershell
python -m engine.main
```
Run this from `c:\Users\Yuki\Documents\Lexi-Core`. Use `WaitMsBeforeAsync: 6000` so it goes to background after confirming startup.

3. Launch the Flutter app:
```powershell
C:\flutter\bin\flutter.bat run -d windows
```
Run this from `c:\Users\Yuki\Documents\Lexi-Core\ui`. Use `WaitMsBeforeAsync: 500` to send to background immediately.

4. Wait for Flutter build to complete (~10-15s), then check output for errors.

## Backend Restart Rules

When you need to restart the backend during development:
- **DO:** Terminate the running command immediately (`Terminate: true`), then kill port 8741, then start fresh
- **DO NOT:** Try to send `Ctrl+C` or wait for graceful shutdown
- **DO NOT:** Wait for terminal output after terminating — just move on and start new

## Notes
- The backend runs on `http://127.0.0.1:8741`
- The Flutter app connects to the backend automatically
- Use `q` in the Flutter terminal to quit the app
- The backend process will keep running in the background; kill port 8741 to stop it
