; ═══════════════════════════════════════════════════════════════
; LexiCore Installer v5.5 — Inno Setup Script (Online Downloader)
; Publisher: Pham Anh
; Downloads source code from GitHub, installs dependencies, builds UI
; 3 install modes: Normal, Tech, Easter Egg (Cipher Mode)
; ═══════════════════════════════════════════════════════════════

#define MyAppName "LexiCore"
#define MyAppVersion "5.5"
#define MyAppPublisher "Pham Anh"
#define MyAppURL "https://github.com/yuki-20/Lexi-Core"
#define MyAppExeName "LexiCore.bat"
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
VersionInfoVersion={#MyAppVersion}.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} — Offline-First Vocabulary Learning Platform
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Only bundle the launcher bat — everything else is downloaded
Source: "LexiCore.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent shellexec; WorkingDir: "{app}"

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
begin
  if DirExists(ExpandConstant('{app}\engine')) then
  begin
    TechLog('[CLEAN] Removing old engine files...');
    DelTree(ExpandConstant('{app}\engine'), True, True, True);
  end;
  if DirExists(ExpandConstant('{app}\ui')) then
  begin
    TechLog('[CLEAN] Removing old UI files...');
    DelTree(ExpandConstant('{app}\ui'), True, True, True);
  end;
  if DirExists(ExpandConstant('{app}\scripts')) then
  begin
    TechLog('[CLEAN] Removing old scripts...');
    DelTree(ExpandConstant('{app}\scripts'), True, True, True);
  end;
end;

// ─── Main install: Download from GitHub + setup ───────────────
procedure DoOnlineInstall();
var
  ResultCode: Integer;
  AppDir, TempZip, TempExtract, SourceDir: String;
  PSCommand: String;
begin
  AppDir := ExpandConstant('{app}');
  TempZip := ExpandConstant('{tmp}\lexicore-main.zip');
  TempExtract := ExpandConstant('{tmp}\lexicore-extract');

  // Step 1: Clean old installation
  ProgressPage.SetProgress(1, 10);
  ProgressPage.SetText('Cleaning previous installation...', '');
  TechLog('[STEP 1/6] Cleaning previous installation...');
  CleanOldInstall();

  // Step 2: Download source from GitHub
  ProgressPage.SetProgress(2, 10);
  ProgressPage.SetText('Downloading LexiCore from GitHub...', '{#MyRepoZip}');
  TechLog('[STEP 2/6] Downloading source from GitHub...');
  TechLog('  URL: {#MyRepoZip}');
  TechLog('  Target: ' + TempZip);

  PSCommand := 'Invoke-WebRequest -Uri "{#MyRepoZip}" -OutFile "' + TempZip + '" -UseBasicParsing';
  if not RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode) then
  begin
    MsgBox('Failed to download LexiCore from GitHub. Please check your internet connection.', mbError, MB_OK);
    Exit;
  end;
  TechLog('  Download complete (exit code: ' + IntToStr(ResultCode) + ')');

  // Step 3: Extract ZIP
  ProgressPage.SetProgress(4, 10);
  ProgressPage.SetText('Extracting source code...', '');
  TechLog('[STEP 3/6] Extracting archive...');
  TechLog('  Source: ' + TempZip);
  TechLog('  Target: ' + TempExtract);

  PSCommand := 'Expand-Archive -Path "' + TempZip + '" -DestinationPath "' + TempExtract + '" -Force';
  RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode);
  TechLog('  Extraction complete');

  SourceDir := TempExtract + '\Lexi-Core-main';

  // Step 4: Copy engine files
  ProgressPage.SetProgress(5, 10);
  ProgressPage.SetText('Installing Python engine...', '');
  TechLog('[STEP 4/6] Copying engine files...');
  TechLog('  From: ' + SourceDir + '\engine');
  TechLog('  To:   ' + AppDir + '\engine');

  PSCommand := 'Copy-Item -Path "' + SourceDir + '\engine" -Destination "' + AppDir + '\engine" -Recurse -Force; ' +
               'Copy-Item -Path "' + SourceDir + '\scripts" -Destination "' + AppDir + '\scripts" -Recurse -Force -ErrorAction SilentlyContinue; ' +
               'Copy-Item -Path "' + SourceDir + '\data" -Destination "' + AppDir + '\data" -Recurse -Force -ErrorAction SilentlyContinue; ' +
               'Copy-Item -Path "' + SourceDir + '\requirements.txt" -Destination "' + AppDir + '\requirements.txt" -Force; ' +
               'Copy-Item -Path "' + SourceDir + '\pyproject.toml" -Destination "' + AppDir + '\pyproject.toml" -Force -ErrorAction SilentlyContinue';
  RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode);
  TechLog('  Engine files copied');

  // Step 5: Install Python dependencies
  ProgressPage.SetProgress(6, 10);
  ProgressPage.SetText('Installing Python dependencies (pip)...', 'This may take a few minutes...');
  TechLog('[STEP 5/6] Installing Python dependencies...');
  TechLog('  Running: pip install -r requirements.txt');

  RunCmd('cmd.exe', '/c pip install -r "' + AppDir + '\requirements.txt" --quiet 2>&1', AppDir, ResultCode);
  if ResultCode = 0 then
    TechLog('  Dependencies installed successfully')
  else
    TechLog('  [WARNING] pip returned exit code: ' + IntToStr(ResultCode));

  // Step 6: Build Flutter UI (if Flutter is available) or download pre-built
  ProgressPage.SetProgress(8, 10);
  ProgressPage.SetText('Setting up LexiCore UI...', '');
  TechLog('[STEP 6/6] Setting up UI...');

  // Try building with Flutter first
  if FileExists('C:\flutter\bin\flutter.bat') then
  begin
    TechLog('  Flutter SDK found. Building release...');
    ProgressPage.SetText('Building LexiCore UI (Flutter)...', 'This may take 1-2 minutes...');

    // Copy the UI source for building
    PSCommand := 'Copy-Item -Path "' + SourceDir + '\ui" -Destination "' + AppDir + '\ui_src" -Recurse -Force';
    RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode);

    // Build Flutter release
    RunCmd('cmd.exe', '/c "C:\flutter\bin\flutter.bat" build windows --release 2>&1', AppDir + '\ui_src', ResultCode);

    if ResultCode = 0 then
    begin
      TechLog('  Flutter build successful');
      // Copy release build to app/ui/
      PSCommand := 'Copy-Item -Path "' + AppDir + '\ui_src\build\windows\x64\runner\Release\*" -Destination "' + AppDir + '\ui" -Recurse -Force; ' +
                   'Remove-Item -Path "' + AppDir + '\ui_src" -Recurse -Force -ErrorAction SilentlyContinue';
      RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode);
      TechLog('  UI deployed to ' + AppDir + '\ui');
    end
    else
    begin
      TechLog('  [WARNING] Flutter build failed (code: ' + IntToStr(ResultCode) + ')');
      TechLog('  Downloading pre-built UI from GitHub Releases...');
      // Fallback: download pre-built release
      PSCommand := 'try { ' +
        'Invoke-WebRequest -Uri "https://github.com/yuki-20/Lexi-Core/releases/download/v5.5/LexiCore_UI.zip" -OutFile "' + ExpandConstant('{tmp}') + '\ui.zip" -UseBasicParsing; ' +
        'Expand-Archive -Path "' + ExpandConstant('{tmp}') + '\ui.zip" -DestinationPath "' + AppDir + '\ui" -Force ' +
        '} catch { Write-Host "Pre-built UI not available" }';
      RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode);
    end;
  end
  else
  begin
    TechLog('  Flutter SDK not found. Downloading pre-built UI...');
    ProgressPage.SetText('Downloading pre-built LexiCore UI...', '');
    PSCommand := 'try { ' +
      'Invoke-WebRequest -Uri "https://github.com/yuki-20/Lexi-Core/releases/download/v5.5/LexiCore_UI.zip" -OutFile "' + ExpandConstant('{tmp}') + '\ui.zip" -UseBasicParsing; ' +
      'Expand-Archive -Path "' + ExpandConstant('{tmp}') + '\ui.zip" -DestinationPath "' + AppDir + '\ui" -Force; ' +
      'Write-Host "UI downloaded and extracted" ' +
      '} catch { Write-Host "Pre-built UI not available — please install Flutter and build manually" }';
    RunCmd('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -Command "' + PSCommand + '"', '', ResultCode);
  end;

  // Cleanup temp files
  ProgressPage.SetProgress(9, 10);
  ProgressPage.SetText('Cleaning up temporary files...', '');
  TechLog('');
  TechLog('[CLEANUP] Removing temporary files...');
  DeleteFile(TempZip);
  DelTree(TempExtract, True, True, True);

  ProgressPage.SetProgress(10, 10);
  ProgressPage.SetText('Installation complete!', '');
  TechLog('');
  TechLog('═══════════════════════════════════════════════════════');
  TechLog('  LexiCore v5.5 installed successfully!');
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
end;
