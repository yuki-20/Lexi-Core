Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set Http = Nothing

' Get the directory where this script is located
ScriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)

' Start the Python backend silently
WshShell.CurrentDirectory = ScriptDir
WshShell.Run "cmd.exe /c python -m engine.main", 0, False

' Wait for backend to be ready (up to 15 seconds — auto-build may take extra time)
Dim ready, attempts
ready = False
attempts = 0
Do While Not ready And attempts < 15
    WScript.Sleep 1000
    attempts = attempts + 1
    On Error Resume Next
    Set Http = CreateObject("MSXML2.XMLHTTP")
    Http.Open "GET", "http://127.0.0.1:8741/api/stats", False
    Http.Send
    If Http.Status = 200 Then ready = True
    Set Http = Nothing
    On Error GoTo 0
Loop

' Launch the Flutter UI
WshShell.Run """" & ScriptDir & "\ui\lexicore_ui.exe""", 1, False
