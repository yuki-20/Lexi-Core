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

2. Start the backend **with hidden window** (no PowerShell popup):
```powershell
Start-Process -FilePath "python" -ArgumentList "-m engine.main" -WorkingDirectory "c:\Users\Yuki\Documents\Lexi-Core" -WindowStyle Hidden
```
Run this from `c:\Users\Yuki\Documents\Lexi-Core`. Use `WaitMsBeforeAsync: 4000` so it goes to background. Then wait ~3s for the server to be ready.

3. Launch the Flutter app:
```powershell
C:\flutter\bin\flutter.bat run -d windows
```
Run this from `c:\Users\Yuki\Documents\Lexi-Core\ui`. Use `WaitMsBeforeAsync: 500` to send to background immediately.

4. Wait for Flutter build to complete (~10-15s), then check output for errors.

## Backend Restart Rules

When you need to restart the backend during development:
- **DO:** Kill port 8741 first, then start the backend with `-WindowStyle Hidden` to avoid popup
- **DO NOT:** Use `Start-Process powershell` which creates a visible window
- **DO NOT:** Try to send `Ctrl+C` or wait for graceful shutdown

## Notes
- The backend runs on `http://127.0.0.1:8741`
- The Flutter app connects to the backend automatically
- Use `q` in the Flutter terminal to quit the app
- The backend process will keep running in the background; kill port 8741 to stop it
