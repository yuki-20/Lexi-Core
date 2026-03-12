Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set Http = Nothing

ScriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)
PythonExe = ScriptDir & "\.venv\Scripts\python.exe"
UiExe = ScriptDir & "\ui\lexicore_ui.exe"
DataDir = ScriptDir & "\data"

If Not FSO.FileExists(PythonExe) Then
    MsgBox "LexiCore runtime is missing. Reinstall the app to recreate the virtual environment.", vbCritical, "LexiCore"
    WScript.Quit 1
End If

If Not FSO.FileExists(UiExe) Then
    MsgBox "LexiCore UI is missing. Reinstall the app to restore the bundled Windows executable.", vbCritical, "LexiCore"
    WScript.Quit 1
End If

If Not FSO.FolderExists(DataDir) Then
    FSO.CreateFolder DataDir
End If

Function BackendReady()
    On Error Resume Next
    BackendReady = False
    Set Http = CreateObject("MSXML2.XMLHTTP")
    Http.Open "GET", "http://127.0.0.1:8741/api/stats", False
    Http.Send
    If Err.Number = 0 Then
        If Http.Status = 200 Then BackendReady = True
    End If
    Set Http = Nothing
    Err.Clear
    On Error GoTo 0
End Function

WshShell.CurrentDirectory = ScriptDir

If Not BackendReady() Then
    WshShell.Environment("PROCESS")("PYTHONUTF8") = "1"
    WshShell.Run "cmd.exe /c """ & PythonExe & """ -m engine.main 1>>""" & DataDir & "\launcher-backend.out.log"" 2>>""" & DataDir & "\launcher-backend.err.log""", 0, False
End If

ready = False
attempts = 0
Do While Not ready And attempts < 30
    WScript.Sleep 1000
    attempts = attempts + 1
    ready = BackendReady()
Loop

If Not ready Then
    MsgBox "LexiCore backend did not become ready within 30 seconds.", vbCritical, "LexiCore"
    WScript.Quit 1
End If

WshShell.Run """" & UiExe & """", 1, False
