---
description: Auto-start the LexiCore backend and Flutter app with a single command
---

# Auto-Run LexiCore

This workflow auto-starts both the Python backend and the Flutter desktop app.

## Steps

// turbo-all

1. Kill any existing process on port 8741:
```powershell
Get-NetTCPConnection -LocalPort 8741 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
```

2. Start the backend in the background:
```powershell
Start-Process -NoNewWindow -FilePath python -ArgumentList "-m engine.main" -WorkingDirectory "c:\Users\Yuki\Documents\Lexi-Core"
```

3. Wait 2 seconds for the backend to initialize:
```powershell
Start-Sleep -Seconds 2
```

4. Launch the Flutter app:
```powershell
C:\flutter\bin\flutter.bat run -d windows
```
Run this from `c:\Users\Yuki\Documents\Lexi-Core\ui`.

## Notes
- The backend runs on `http://127.0.0.1:8741`
- The Flutter app connects to the backend automatically
- Use `q` in the Flutter terminal to quit the app
- The backend process will keep running in the background; kill port 8741 to stop it
