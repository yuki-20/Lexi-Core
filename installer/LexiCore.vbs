Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Get the directory where this script is located
ScriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)

' Start the Python backend silently
WshShell.CurrentDirectory = ScriptDir
WshShell.Run "cmd.exe /c python -m engine.main", 0, False

' Wait for backend to start
WScript.Sleep 4000

' Launch the Flutter UI
WshShell.Run """" & ScriptDir & "\ui\lexicore_ui.exe""", 1, False
