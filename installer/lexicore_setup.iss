; ═══════════════════════════════════════════════════════════════
; LexiCore Installer v5.5 — Inno Setup Script
; Publisher: Pham Anh
; 3 install modes: Normal, Tech, Easter Egg (Cipher Mode)
; ═══════════════════════════════════════════════════════════════

#define MyAppName "LexiCore"
#define MyAppVersion "5.5"
#define MyAppPublisher "Pham Anh"
#define MyAppURL "https://github.com/yuki-20/Lexi-Core"
#define MyAppExeName "LexiCore.bat"

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
; Output settings
OutputDir=output
OutputBaseFilename=LexiCore_Setup_v{#MyAppVersion}
SetupIconFile=..\ui\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
; Appearance
WizardImageFile=compiler:WizModernImage.bmp
WizardSmallImageFile=compiler:WizModernSmallImage.bmp
; Privileges
PrivilegesRequired=admin
; Uninstall
UninstallDisplayIcon={app}\ui\lexicore_ui.exe
UninstallDisplayName={#MyAppName}
; Version info
VersionInfoVersion={#MyAppVersion}.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} — Offline-First Vocabulary Learning Platform
VersionInfoCopyright=Copyright (C) 2026 {#MyAppPublisher}
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
ModeNormal=Normal Mode — Clean, compact installation
ModeTech=Tech Mode — Show everything the installer does
ModeCipher=??? — Classified

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; === Flutter Release Build ===
Source: "..\ui\build\windows\x64\runner\Release\*"; DestDir: "{app}\ui"; Flags: ignoreversion recursesubdirs createallsubdirs; AfterInstall: LogInstall('Flutter UI')

; === Python Backend Engine ===
Source: "..\engine\*"; DestDir: "{app}\engine"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "__pycache__,*.pyc,ai_config.json,.pytest_cache"; AfterInstall: LogInstall('Python Engine')

; === Data directory (empty, for user data) ===
Source: "..\data\.gitkeep"; DestDir: "{app}\data"; Flags: ignoreversion

; === Scripts ===
Source: "..\scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion recursesubdirs; AfterInstall: LogInstall('Scripts')

; === Config files ===
Source: "..\requirements.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\pyproject.toml"; DestDir: "{app}"; Flags: ignoreversion

; === Launcher ===
Source: "LexiCore.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\ui\lexicore_ui.exe"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\ui\lexicore_ui.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent shellexec; WorkingDir: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\engine\__pycache__"

[Code]
var
  ModePage: TWizardPage;
  ModeNormalRadio: TNewRadioButton;
  ModeTechRadio: TNewRadioButton;
  ModeCipherRadio: TNewRadioButton;
  OutputMemo: TNewMemo;
  SelectedMode: Integer; // 0=Normal, 1=Tech, 2=Cipher
  CipherLines: TStringList;
  CipherTimer: Integer;

procedure LogInstall(Component: String);
begin
  if SelectedMode = 1 then
  begin
    if OutputMemo <> nil then
    begin
      OutputMemo.Lines.Add('[INSTALL] Copying: ' + Component + '...');
      OutputMemo.Lines.Add('  -> ' + ExpandConstant('{app}'));
    end;
  end;
end;

procedure InitializeWizard();
var
  ModeLabel: TNewStaticText;
begin
  // Create mode selection page
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

  // Normal mode radio
  ModeNormalRadio := TNewRadioButton.Create(ModePage);
  ModeNormalRadio.Parent := ModePage.Surface;
  ModeNormalRadio.Caption := '  Normal Mode — Clean, compact installation';
  ModeNormalRadio.Top := 50;
  ModeNormalRadio.Left := 20;
  ModeNormalRadio.Width := 400;
  ModeNormalRadio.Height := 24;
  ModeNormalRadio.Checked := True;
  ModeNormalRadio.Font.Size := 10;

  // Tech mode radio
  ModeTechRadio := TNewRadioButton.Create(ModePage);
  ModeTechRadio.Parent := ModePage.Surface;
  ModeTechRadio.Caption := '  Tech Mode — Show everything the installer does';
  ModeTechRadio.Top := 85;
  ModeTechRadio.Left := 20;
  ModeTechRadio.Width := 400;
  ModeTechRadio.Height := 24;
  ModeTechRadio.Font.Size := 10;

  // Cipher mode radio (Easter Egg)
  ModeCipherRadio := TNewRadioButton.Create(ModePage);
  ModeCipherRadio.Parent := ModePage.Surface;
  ModeCipherRadio.Caption := '  ??? — [CLASSIFIED]';
  ModeCipherRadio.Top := 120;
  ModeCipherRadio.Left := 20;
  ModeCipherRadio.Width := 400;
  ModeCipherRadio.Height := 24;
  ModeCipherRadio.Font.Size := 10;
  ModeCipherRadio.Font.Color := $00FF88;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
  begin
    // Determine selected mode
    if ModeTechRadio.Checked then
      SelectedMode := 1
    else if ModeCipherRadio.Checked then
      SelectedMode := 2
    else
      SelectedMode := 0;
  end;

  if CurStep = ssPostInstall then
  begin
    // Install Python dependencies
    if SelectedMode = 1 then
    begin
      if OutputMemo <> nil then
        OutputMemo.Lines.Add('[SETUP] Installing Python dependencies...');
    end;

    Exec('cmd.exe', '/c pip install -r "' + ExpandConstant('{app}') + '\requirements.txt" --quiet',
         ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, ResultCode);

    if SelectedMode = 1 then
    begin
      if OutputMemo <> nil then
      begin
        if ResultCode = 0 then
          OutputMemo.Lines.Add('[SUCCESS] Python dependencies installed.')
        else
          OutputMemo.Lines.Add('[WARNING] pip install returned code: ' + IntToStr(ResultCode));
      end;
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  I: Integer;
  CipherText: TStringList;
begin
  // When entering the installing page...
  if CurPageID = wpInstalling then
  begin
    if SelectedMode = 1 then
    begin
      // Tech Mode: Show output memo
      OutputMemo := TNewMemo.Create(WizardForm);
      OutputMemo.Parent := WizardForm.InnerPage;
      OutputMemo.Left := 0;
      OutputMemo.Top := 160;
      OutputMemo.Width := WizardForm.InnerPage.ClientWidth;
      OutputMemo.Height := 140;
      OutputMemo.ScrollBars := ssVertical;
      OutputMemo.ReadOnly := True;
      OutputMemo.Color := $1E1E1E;
      OutputMemo.Font.Color := $00FF00;
      OutputMemo.Font.Name := 'Consolas';
      OutputMemo.Font.Size := 9;
      OutputMemo.Lines.Add('═══════════════════════════════════════════');
      OutputMemo.Lines.Add('  LexiCore v5.5 — Tech Mode Installation  ');
      OutputMemo.Lines.Add('═══════════════════════════════════════════');
      OutputMemo.Lines.Add('');
      OutputMemo.Lines.Add('[INIT] Target: ' + ExpandConstant('{app}'));
      OutputMemo.Lines.Add('[INIT] Mode: Verbose / Technical');
      OutputMemo.Lines.Add('[INIT] Beginning file deployment...');
      OutputMemo.Lines.Add('');
    end
    else if SelectedMode = 2 then
    begin
      // Cipher Mode (Easter Egg): Matrix-style hacker terminal
      OutputMemo := TNewMemo.Create(WizardForm);
      OutputMemo.Parent := WizardForm.InnerPage;
      OutputMemo.Left := 0;
      OutputMemo.Top := 0;
      OutputMemo.Width := WizardForm.InnerPage.ClientWidth;
      OutputMemo.Height := WizardForm.InnerPage.ClientHeight;
      OutputMemo.ScrollBars := ssVertical;
      OutputMemo.ReadOnly := True;
      OutputMemo.Color := $000000;
      OutputMemo.Font.Color := $00FF41;
      OutputMemo.Font.Name := 'Consolas';
      OutputMemo.Font.Size := 9;

      CipherText := TStringList.Create;
      CipherText.Add('');
      CipherText.Add('  ╔══════════════════════════════════════════════════════╗');
      CipherText.Add('  ║   L E X I C O R E   //   C I P H E R   M O D E     ║');
      CipherText.Add('  ╚══════════════════════════════════════════════════════╝');
      CipherText.Add('');
      CipherText.Add('  > Establishing secure tunnel to lexicon mainframe...');
      CipherText.Add('  > Connection established: 127.0.0.1:8741');
      CipherText.Add('  > Handshake protocol: LEXICON-AES-256-GLASS');
      CipherText.Add('');
      CipherText.Add('  $ sudo decrypt --neural-network /core/vocabulary.dat');
      CipherText.Add('    [████████████████████████████████] 100%');
      CipherText.Add('    STATUS: Neural vocabulary pathways activated');
      CipherText.Add('');
      CipherText.Add('  $ calibrate --lexicon-matrix --depth=infinite');
      CipherText.Add('    Scanning 300,000+ word nodes...');
      CipherText.Add('    Huffman tree depth: 42 (Answer to everything)');
      CipherText.Add('    Bloom filter: 0.001% false positive rate');
      CipherText.Add('    Trie nodes: 1,847,293 allocated');
      CipherText.Add('    TF-IDF vectors: Normalized across 150K definitions');
      CipherText.Add('');
      CipherText.Add('  $ init --spaced-repetition --algorithm=SM2');
      CipherText.Add('    Interval scheduler: ONLINE');
      CipherText.Add('    Memory decay model: Ebbinghaus curve loaded');
      CipherText.Add('    Optimal recall threshold: 0.85');
      CipherText.Add('');
      CipherText.Add('  $ deploy --liquid-glass-ui --renderer=GPU');
      CipherText.Add('    CustomPainter shaders: Compiled');
      CipherText.Add('    Glassmorphism layers: 7 (iOS 26 spec)');
      CipherText.Add('    Animation controllers: 12 active');
      CipherText.Add('    Frame budget: 16.6ms (60 FPS locked)');
      CipherText.Add('');
      CipherText.Add('  $ connect --ai-models --count=10');
      CipherText.Add('    DeepSeek-R1.............. ONLINE');
      CipherText.Add('    Qwen3-32B................ ONLINE');
      CipherText.Add('    Gemma 3 27B (Vision)..... ONLINE');
      CipherText.Add('    Llama-3.3-70B............ ONLINE');
      CipherText.Add('    Chain-of-Thought: ENABLED');
      CipherText.Add('    Web Search (RAG): ACTIVE');
      CipherText.Add('');
      CipherText.Add('  $ finalize --installation');
      CipherText.Add('    All systems nominal.');
      CipherText.Add('    XP Engine: Level^2 curve, max 1000');
      CipherText.Add('    Streak Pets: 4 companions standing by');
      CipherText.Add('    Daily Quests: Loaded');
      CipherText.Add('');
      CipherText.Add('  ┌─────────────────────────────────────────────────────┐');
      CipherText.Add('  │                                                     │');
      CipherText.Add('  │  "The limits of my language mean the limits of      │');
      CipherText.Add('  │   my world."                                        │');
      CipherText.Add('  │                        — Ludwig Wittgenstein        │');
      CipherText.Add('  │                                                     │');
      CipherText.Add('  │  "One language sets you in a corridor for life.     │');
      CipherText.Add('  │   Two languages open every door along the way."     │');
      CipherText.Add('  │                        — Frank Smith               │');
      CipherText.Add('  │                                                     │');
      CipherText.Add('  └─────────────────────────────────────────────────────┘');
      CipherText.Add('');
      CipherText.Add('  > Installation complete. Welcome, Operator.');
      CipherText.Add('  > LexiCore v5.5 is ready. Your journey begins now.');
      CipherText.Add('');

      for I := 0 to CipherText.Count - 1 do
      begin
        OutputMemo.Lines.Add(CipherText[I]);
      end;

      CipherText.Free;
    end;
  end;
end;

// Uninstall: remove old files before installing new ones
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  OldDir: String;
begin
  Result := '';
  OldDir := ExpandConstant('{app}');
  if DirExists(OldDir) then
  begin
    if SelectedMode = 1 then
    begin
      MsgBox('Removing previous installation at: ' + OldDir, mbInformation, MB_OK);
    end;
    DelTree(OldDir + '\ui', True, True, True);
    DelTree(OldDir + '\engine\__pycache__', True, True, True);
  end;
end;
