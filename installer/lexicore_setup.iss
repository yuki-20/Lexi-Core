; ═══════════════════════════════════════════════════════════════
; LexiCore Installer v5.5 — Inno Setup Script (Online Downloader)
; Publisher: Pham Anh
; Downloads source code from GitHub, installs dependencies, builds UI
; 3 install modes: Normal, Tech, Easter Egg (Cipher Mode)
; ═══════════════════════════════════════════════════════════════

#define MyAppName "LexiCore"
#define MyAppVersion "5.5.1"
#define MyAppPublisher "Pham Anh"
#define MyAppURL "https://github.com/yuki-20/Lexi-Core"
#define MyAppExeName "LexiCore.vbs"
#define MyRepoZip "https://github.com/yuki-20/Lexi-Core/archive/refs/heads/main.zip"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=output
OutputBaseFilename=LexiCore_Setup_v{#MyAppVersion}
SetupIconFile=..\ui\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayName={#MyAppName}
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} — Offline-First Vocabulary Learning Platform
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Launcher scripts — everything else is downloaded from GitHub
Source: "LexiCore.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "LexiCore.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "LexiCore_UI.zip"; Flags: dontcopy

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "wscript.exe"; Parameters: """{app}\LexiCore.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\ui\lexicore_ui.exe"; Comment: "Launch LexiCore"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "wscript.exe"; Parameters: """{app}\LexiCore.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\ui\lexicore_ui.exe"; Tasks: desktopicon; Comment: "Launch LexiCore"

[Run]
Filename: "wscript.exe"; Parameters: """{app}\LexiCore.vbs"""; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent; WorkingDir: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
var
  ModePage: TWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  ModeNormalRadio: TNewRadioButton;
  ModeTechRadio: TNewRadioButton;
  ModeCipherRadio: TNewRadioButton;
  OutputMemo: TNewMemo;
  SelectedMode: Integer;
  InstallError: String;

// ─── Utility: Log to tech/cipher output ───────────────────────
procedure TechLog(Msg: String);
begin
  if (SelectedMode >= 1) and (OutputMemo <> nil) then
  begin
    OutputMemo.Lines.Add(Msg);
    // Auto-scroll to bottom
    OutputMemo.SelStart := Length(OutputMemo.Text);
  end;
end;

// ─── Utility: Run a command and capture exit code ─────────────
function RunCmd(Cmd, Params, WorkDir: String; var ExitCode: Integer): Boolean;
begin
  Result := Exec(Cmd, Params, WorkDir, SW_HIDE, ewWaitUntilTerminated, ExitCode);
end;

procedure FailInstall(Msg: String);
begin
  InstallError := Msg;
  TechLog('[ERROR] ' + Msg);
  MsgBox(Msg, mbError, MB_OK);
end;

function DetectPythonLauncher(): String;
var
  ResultCode: Integer;
begin
  Result := '';
  if RunCmd('cmd.exe', '/c py -3 --version >nul 2>&1', '', ResultCode) and (ResultCode = 0) then
  begin
    Result := 'py -3';
    Exit;
  end;
  if RunCmd('cmd.exe', '/c python --version >nul 2>&1', '', ResultCode) and (ResultCode = 0) then
    Result := 'python';
end;

// ─── Initialize wizard: Create mode selection page ────────────
procedure InitializeWizard();
var
  ModeLabel: TNewStaticText;
  DescLabel: TNewStaticText;
begin
  ModePage := CreateCustomPage(wpWelcome,
    'Installation Mode',
    'Choose how you want to experience the installation.');

  ModeLabel := TNewStaticText.Create(ModePage);
  ModeLabel.Parent := ModePage.Surface;
  ModeLabel.Caption := 'Select your preferred installation style:';
  ModeLabel.Top := 10;
  ModeLabel.Left := 0;
  ModeLabel.Font.Style := [fsBold];
  ModeLabel.Font.Size := 10;

  // Normal mode
  ModeNormalRadio := TNewRadioButton.Create(ModePage);
  ModeNormalRadio.Parent := ModePage.Surface;
  ModeNormalRadio.Caption := '  Normal Mode';
  ModeNormalRadio.Top := 50;
  ModeNormalRadio.Left := 20;
  ModeNormalRadio.Width := 400;
  ModeNormalRadio.Height := 24;
  ModeNormalRadio.Checked := True;
  ModeNormalRadio.Font.Size := 10;

  DescLabel := TNewStaticText.Create(ModePage);
  DescLabel.Parent := ModePage.Surface;
  DescLabel.Caption := 'Clean, compact installation with progress bar';
  DescLabel.Top := 72;
  DescLabel.Left := 44;
  DescLabel.Font.Color := $888888;
  DescLabel.Font.Size := 9;

  // Tech mode
  ModeTechRadio := TNewRadioButton.Create(ModePage);
  ModeTechRadio.Parent := ModePage.Surface;
  ModeTechRadio.Caption := '  Tech Mode';
  ModeTechRadio.Top := 100;
  ModeTechRadio.Left := 20;
  ModeTechRadio.Width := 400;
  ModeTechRadio.Height := 24;
  ModeTechRadio.Font.Size := 10;

  DescLabel := TNewStaticText.Create(ModePage);
  DescLabel.Parent := ModePage.Surface;
  DescLabel.Caption := 'Show everything: downloads, file copies, pip install output';
  DescLabel.Top := 122;
  DescLabel.Left := 44;
  DescLabel.Font.Color := $888888;
  DescLabel.Font.Size := 9;

  // Cipher mode (Easter Egg)
  ModeCipherRadio := TNewRadioButton.Create(ModePage);
  ModeCipherRadio.Parent := ModePage.Surface;
  ModeCipherRadio.Caption := '  ??? — [CLASSIFIED]';
  ModeCipherRadio.Top := 150;
  ModeCipherRadio.Left := 20;
  ModeCipherRadio.Width := 400;
  ModeCipherRadio.Height := 24;
  ModeCipherRadio.Font.Size := 10;
  ModeCipherRadio.Font.Color := $00FF88;

  DescLabel := TNewStaticText.Create(ModePage);
  DescLabel.Parent := ModePage.Surface;
  DescLabel.Caption := 'Access Level: CLASSIFIED';
  DescLabel.Top := 172;
  DescLabel.Left := 44;
  DescLabel.Font.Color := $00AA66;
  DescLabel.Font.Size := 9;

  // Progress page for custom download
  ProgressPage := CreateOutputProgressPage('Installing LexiCore',
    'Downloading and setting up LexiCore from GitHub...');
end;

// ─── Show Cipher Easter Egg ───────────────────────────────────
procedure ShowCipherEasterEgg();
begin
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  ╔══════════════════════════════════════════════════════╗');
  OutputMemo.Lines.Add('  ║   L E X I C O R E   //   C I P H E R   M O D E     ║');
  OutputMemo.Lines.Add('  ╚══════════════════════════════════════════════════════╝');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  > Establishing secure tunnel to lexicon mainframe...');
  OutputMemo.Lines.Add('  > Connection established: 127.0.0.1:8741');
  OutputMemo.Lines.Add('  > Handshake protocol: LEXICON-AES-256-GLASS');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  $ sudo decrypt --neural-network /core/vocabulary.dat');
  OutputMemo.Lines.Add('    [████████████████████████████████] 100%');
  OutputMemo.Lines.Add('    STATUS: Neural vocabulary pathways activated');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  $ calibrate --lexicon-matrix --depth=infinite');
  OutputMemo.Lines.Add('    Scanning 300,000+ word nodes...');
  OutputMemo.Lines.Add('    Huffman tree depth: 42 (Answer to everything)');
  OutputMemo.Lines.Add('    Bloom filter: 0.001% false positive rate');
  OutputMemo.Lines.Add('    Trie nodes: 1,847,293 allocated');
  OutputMemo.Lines.Add('    TF-IDF vectors: Normalized across 150K definitions');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  $ init --spaced-repetition --algorithm=SM2');
  OutputMemo.Lines.Add('    Interval scheduler: ONLINE');
  OutputMemo.Lines.Add('    Memory decay model: Ebbinghaus curve loaded');
  OutputMemo.Lines.Add('    Optimal recall threshold: 0.85');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  $ deploy --liquid-glass-ui --renderer=GPU');
  OutputMemo.Lines.Add('    CustomPainter shaders: Compiled');
  OutputMemo.Lines.Add('    Glassmorphism layers: 7 (iOS 26 spec)');
  OutputMemo.Lines.Add('    Animation controllers: 12 active');
  OutputMemo.Lines.Add('    Frame budget: 16.6ms (60 FPS locked)');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  $ connect --ai-models --count=10');
  OutputMemo.Lines.Add('    DeepSeek-R1.............. ONLINE');
  OutputMemo.Lines.Add('    Qwen3-32B................ ONLINE');
  OutputMemo.Lines.Add('    Gemma 3 27B (Vision)..... ONLINE');
  OutputMemo.Lines.Add('    Llama-3.3-70B............ ONLINE');
  OutputMemo.Lines.Add('    Chain-of-Thought: ENABLED');
  OutputMemo.Lines.Add('    Web Search (RAG): ACTIVE');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  $ finalize --installation');
  OutputMemo.Lines.Add('    All systems nominal.');
  OutputMemo.Lines.Add('    XP Engine: Level^2 curve, max 1000');
  OutputMemo.Lines.Add('    Streak Pets: 4 companions standing by');
  OutputMemo.Lines.Add('    Daily Quests: Loaded');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  ┌─────────────────────────────────────────────────────┐');
  OutputMemo.Lines.Add('  │                                                     │');
  OutputMemo.Lines.Add('  │  "The limits of my language mean the limits of      │');
  OutputMemo.Lines.Add('  │   my world."                                        │');
  OutputMemo.Lines.Add('  │                        — Ludwig Wittgenstein        │');
  OutputMemo.Lines.Add('  │                                                     │');
  OutputMemo.Lines.Add('  │  "One language sets you in a corridor for life.     │');
  OutputMemo.Lines.Add('  │   Two languages open every door along the way."     │');
  OutputMemo.Lines.Add('  │                        — Frank Smith               │');
  OutputMemo.Lines.Add('  │                                                     │');
  OutputMemo.Lines.Add('  └─────────────────────────────────────────────────────┘');
  OutputMemo.Lines.Add('');
  OutputMemo.Lines.Add('  > Installation complete. Welcome, Operator.');
  OutputMemo.Lines.Add('  > LexiCore v5.5 is ready. Your journey begins now.');
  OutputMemo.Lines.Add('');
end;

// ─── Create output memo (for Tech and Cipher modes) ──────────
procedure CreateOutputMemo();
begin
  OutputMemo := TNewMemo.Create(WizardForm);
  OutputMemo.Parent := WizardForm.InnerPage;
  OutputMemo.ScrollBars := ssVertical;
  OutputMemo.ReadOnly := True;
  OutputMemo.Font.Name := 'Consolas';
  OutputMemo.Font.Size := 9;

  if SelectedMode = 2 then
  begin
    // Cipher mode — full screen black/green
    OutputMemo.Left := 0;
    OutputMemo.Top := 0;
    OutputMemo.Width := WizardForm.InnerPage.ClientWidth;
    OutputMemo.Height := WizardForm.InnerPage.ClientHeight;
    OutputMemo.Color := $000000;
    OutputMemo.Font.Color := $00FF41;
  end
  else
  begin
    // Tech mode — partial panel
    OutputMemo.Left := 0;
    OutputMemo.Top := 160;
    OutputMemo.Width := WizardForm.InnerPage.ClientWidth;
    OutputMemo.Height := 140;
    OutputMemo.Color := $1E1E1E;
    OutputMemo.Font.Color := $00FF00;
  end;
end;

// ─── Remove old installation ──────────────────────────────────
procedure CleanOldInstall();
var
  ResultCode: Integer;
  AppDir: String;
begin
  AppDir := ExpandConstant('{app}');
  TechLog('[CLEAN] Stopping running LexiCore processes...');
  Exec('cmd.exe', '/c taskkill /f /im lexicore_ui.exe 2>nul', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('cmd.exe', '/c for /f "tokens=5" %a in (''netstat -aon ^| findstr :8741'') do taskkill /f /pid %a 2>nul', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(1000);

  if DirExists(AppDir) then
  begin
    TechLog('[CLEAN] Removing old installation tree...');
    DelTree(AppDir, True, True, True);
  end;

  ForceDirectories(AppDir);
end;

// ─── Main install: Download from GitHub + setup ───────────────
procedure DoOnlineInstall();
var
  ResultCode: Integer;
  AppDir, TempZip, TempExtract, SourceDir, TempUIZip: String;
  PythonLauncher, VenvPython: String;
begin
  InstallError := '';
  AppDir := ExpandConstant('{app}');
  TempZip := ExpandConstant('{tmp}\lexicore-main.zip');
  TempUIZip := ExpandConstant('{tmp}\LexiCore_UI.zip');
  TempExtract := ExpandConstant('{tmp}\lexicore-extract');

  // Step 1: Clean old installation
  ProgressPage.SetProgress(1, 10);
  ProgressPage.SetText('Cleaning previous installation...', '');
  TechLog('[STEP 1/6] Cleaning previous installation...');
  CleanOldInstall();

  // Step 2: Download source from GitHub using curl.exe
  ProgressPage.SetProgress(2, 10);
  ProgressPage.SetText('Downloading LexiCore from GitHub...', '{#MyRepoZip}');
  TechLog('[STEP 2/6] Downloading source from GitHub...');
  TechLog('  URL: {#MyRepoZip}');
  TechLog('  Using: curl.exe (follows redirects)');

  if not RunCmd(ExpandConstant('{sys}\curl.exe'),
    '-L -o "' + TempZip + '" "{#MyRepoZip}" --ssl-no-revoke -s',
    '', ResultCode) then
  begin
    FailInstall('Failed to download LexiCore. Please check your internet connection.');
    Exit;
  end;

  if ResultCode <> 0 then
  begin
    FailInstall('Download failed (curl exit code: ' + IntToStr(ResultCode) + '). Check your internet connection.');
    Exit;
  end;
  TechLog('  Download complete');

  // Step 3: Extract source ZIP using tar.exe (built into Windows 10+)
  ProgressPage.SetProgress(4, 10);
  ProgressPage.SetText('Extracting source code...', '');
  TechLog('[STEP 3/6] Extracting archive...');

  ForceDirectories(TempExtract);
  RunCmd(ExpandConstant('{sys}\tar.exe'),
    '-xf "' + TempZip + '" -C "' + TempExtract + '"',
    '', ResultCode);
  if ResultCode <> 0 then
  begin
    FailInstall('Could not extract the LexiCore source archive.');
    Exit;
  end;
  TechLog('  Extraction complete (exit code: ' + IntToStr(ResultCode) + ')');

  SourceDir := TempExtract + '\Lexi-Core-main';
  if not DirExists(SourceDir) then
  begin
    FailInstall('Downloaded archive did not contain the expected Lexi-Core-main folder.');
    Exit;
  end;

  // Step 4: Copy engine + support files using xcopy (works everywhere)
  ProgressPage.SetProgress(5, 10);
  ProgressPage.SetText('Installing Python engine...', '');
  TechLog('[STEP 4/6] Copying engine files...');

  ForceDirectories(AppDir + '\engine');
  RunCmd('cmd.exe', '/c xcopy "' + SourceDir + '\engine" "' + AppDir + '\engine" /E /I /Y /Q', '', ResultCode);
  if ResultCode > 1 then
  begin
    FailInstall('Failed to copy engine files into the installation directory.');
    Exit;
  end;
  TechLog('  Engine copied (exit code: ' + IntToStr(ResultCode) + ')');

  RunCmd('cmd.exe', '/c if exist "' + SourceDir + '\scripts" xcopy "' + SourceDir + '\scripts" "' + AppDir + '\scripts" /E /I /Y /Q', '', ResultCode);
  if ResultCode > 1 then
  begin
    FailInstall('Failed to copy supporting scripts into the installation directory.');
    Exit;
  end;
  ForceDirectories(AppDir + '\data');
  RunCmd('cmd.exe', '/c if exist "' + SourceDir + '\requirements.txt" copy /Y "' + SourceDir + '\requirements.txt" "' + AppDir + '\requirements.txt"', '', ResultCode);
  RunCmd('cmd.exe', '/c if exist "' + SourceDir + '\requirements-dev.txt" copy /Y "' + SourceDir + '\requirements-dev.txt" "' + AppDir + '\requirements-dev.txt"', '', ResultCode);
  RunCmd('cmd.exe', '/c if exist "' + SourceDir + '\pyproject.toml" copy /Y "' + SourceDir + '\pyproject.toml" "' + AppDir + '\pyproject.toml"', '', ResultCode);
  TechLog('  All source files copied');

  // Step 5: Create venv, install Python dependencies, and build data
  ProgressPage.SetProgress(6, 10);
  ProgressPage.SetText('Creating virtual environment and installing dependencies...', 'This may take a few minutes...');
  TechLog('[STEP 5/6] Creating isolated Python runtime...');

  PythonLauncher := DetectPythonLauncher();
  if PythonLauncher = '' then
  begin
    FailInstall('Python 3.12+ was not found. Install Python, ensure it is on PATH, and rerun setup.');
    Exit;
  end;

  RunCmd('cmd.exe', '/c ' + PythonLauncher + ' -m venv "' + AppDir + '\.venv"', AppDir, ResultCode);
  if ResultCode <> 0 then
  begin
    FailInstall('Failed to create the LexiCore virtual environment.');
    Exit;
  end;

  VenvPython := AppDir + '\.venv\Scripts\python.exe';
  if not FileExists(VenvPython) then
  begin
    FailInstall('The virtual environment was created without python.exe. Setup cannot continue.');
    Exit;
  end;

  RunCmd('cmd.exe', '/c "' + VenvPython + '" -m pip install --upgrade pip --disable-pip-version-check', AppDir, ResultCode);
  if ResultCode <> 0 then
  begin
    FailInstall('Failed to upgrade pip inside the LexiCore virtual environment.');
    Exit;
  end;

  RunCmd('cmd.exe', '/c "' + VenvPython + '" -m pip install --disable-pip-version-check -r "' + AppDir + '\requirements.txt"', AppDir, ResultCode);
  if ResultCode <> 0 then
  begin
    FailInstall('Python dependencies failed to install. Setup stopped before writing a broken installation.');
    Exit;
  end;
  TechLog('  Runtime dependencies installed successfully');

  RunCmd('cmd.exe', '/c "' + VenvPython + '" -m engine.data.builder "' + AppDir + '\scripts\sample_dictionary.json"', AppDir, ResultCode);
  if ResultCode <> 0 then
  begin
    FailInstall('LexiCore could not build its initial dictionary data.');
    Exit;
  end;

  if (not FileExists(AppDir + '\data\index.data')) or (not FileExists(AppDir + '\data\meaning.bin')) then
  begin
    FailInstall('Dictionary build finished without producing index.data and meaning.bin.');
    Exit;
  end;

  // Step 6: Extract bundled UI
  ProgressPage.SetProgress(7, 10);
  ProgressPage.SetText('Installing LexiCore UI...', 'Extracting bundled Windows release...');
  TechLog('[STEP 6/6] Installing bundled Windows UI...');

  ForceDirectories(AppDir + '\ui');
  ExtractTemporaryFile('LexiCore_UI.zip');
  if not FileExists(TempUIZip) then
  begin
    FailInstall('Bundled LexiCore_UI.zip was not found inside the installer package.');
    Exit;
  end;

  RunCmd(ExpandConstant('{sys}\tar.exe'),
    '-xf "' + TempUIZip + '" -C "' + AppDir + '\ui"',
    '', ResultCode);
  if ResultCode <> 0 then
  begin
    FailInstall('The bundled Windows UI could not be extracted.');
    Exit;
  end;
  if not FileExists(AppDir + '\ui\lexicore_ui.exe') then
  begin
    FailInstall('The bundled Windows UI did not produce ui\lexicore_ui.exe.');
    Exit;
  end;
  TechLog('  UI extracted successfully');

  // Cleanup temp files
  ProgressPage.SetProgress(9, 10);
  ProgressPage.SetText('Cleaning up temporary files...', '');
  TechLog('');
  TechLog('[CLEANUP] Removing temporary files...');
  DeleteFile(TempZip);
  DeleteFile(TempUIZip);
  DelTree(TempExtract, True, True, True);

  ProgressPage.SetProgress(10, 10);
  ProgressPage.SetText('Installation complete!', '');
  TechLog('');
  TechLog('═══════════════════════════════════════════════════════');
  TechLog('  LexiCore v5.5.1 installed successfully!');
  TechLog('  Location: ' + AppDir);
  TechLog('═══════════════════════════════════════════════════════');

  if SelectedMode = 2 then
    ShowCipherEasterEgg();
end;

// ─── Determine mode when install starts ───────────────────────
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    if ModeTechRadio.Checked then
      SelectedMode := 1
    else if ModeCipherRadio.Checked then
      SelectedMode := 2
    else
      SelectedMode := 0;
  end;
end;

// ─── Run online install after file copy ───────────────────────
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    // Show Tech/Cipher memo if needed
    if SelectedMode >= 1 then
    begin
      CreateOutputMemo();

      if SelectedMode = 1 then
      begin
        OutputMemo.Lines.Add('═══════════════════════════════════════════════════════');
        OutputMemo.Lines.Add('  LexiCore v5.5 — Tech Mode Installation');
        OutputMemo.Lines.Add('═══════════════════════════════════════════════════════');
        OutputMemo.Lines.Add('');
      end;
    end;
  end;
end;

// ─── Run the download + install before the finish page ────────
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  InstallError := '';

  // Determine mode
  if ModeTechRadio.Checked then
    SelectedMode := 1
  else if ModeCipherRadio.Checked then
    SelectedMode := 2
  else
    SelectedMode := 0;

  // Create output memo for Tech/Cipher
  if SelectedMode >= 1 then
    CreateOutputMemo();

  // Show progress page and run online install
  ProgressPage.Show;
  try
    DoOnlineInstall();
  finally
    ProgressPage.Hide;
  end;

  Result := InstallError;
end;

// ─── Kill LexiCore processes before uninstall ─────────────────
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    // Kill the LexiCore UI and Python backend before removing files
    Exec('cmd.exe', '/c taskkill /f /im lexicore_ui.exe 2>nul', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('cmd.exe', '/c taskkill /f /im python.exe /fi "WINDOWTITLE eq LexiCore*" 2>nul', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    // Kill any python process running the engine on port 8741
    Exec('cmd.exe', '/c for /f "tokens=5" %a in (''netstat -aon ^| findstr :8741'') do taskkill /f /pid %a 2>nul', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    // Small delay to let processes fully terminate
    Sleep(1000);
  end;
end;
