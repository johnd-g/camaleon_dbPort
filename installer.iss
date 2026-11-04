; =========================
; Camaleon DB Port - installer.iss
; Build first:  fvm flutter build windows --release
; Then compile this script with Inno Setup.
; Uses thirdparty\ VC++ and MariaDB 10.3 MSI.
; =========================

#define MyAppName "Camaleon DB Port"
#define MyAppNameShort "CamaleonDBPort"
#define MyAppExeName "camaleon_db_port.exe"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "Camaleon Systems Inc"

[Setup]
AppId={{A8C3E2F1-7B4D-4E9A-9C21-5D6F8A0B1E44}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={commonpf}\{#MyAppNameShort}
DefaultGroupName={#MyAppName}
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=dist
OutputBaseFilename=CamaleonDBPort_Setup
Compression=lzma2/ultra64
SolidCompression=yes
CloseApplications=force
CloseApplicationsFilter=*.exe,*.dll
RestartApplications=no
RestartIfNeededByRun=no
DisableProgramGroupPage=yes
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
ShowLanguageDialog=auto
LanguageDetectionMethod=uilanguage
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[CustomMessages]
english.TaskVerbose=Show detailed installation (verbose)
spanish.TaskVerbose=Ver instalación en modo detallado (verbose)
english.TaskStartMenuIcon=Create a Start Menu shortcut
spanish.TaskStartMenuIcon=Crear acceso en el Menú Inicio
english.StatusGrantingPermissions=Granting write permissions...
spanish.StatusGrantingPermissions=Otorgando permisos de escritura...
english.StatusInstallVCRedistX64=Installing Visual C++ Redistributable (x64)...
spanish.StatusInstallVCRedistX64=Instalando Visual C++ Redistributable (x64)...
english.StatusInstallMariaDB=Installing MariaDB 10.3...
spanish.StatusInstallMariaDB=Instalando MariaDB 10.3...
english.StatusStopApp=Closing Camaleon DB Port...
spanish.StatusStopApp=Cerrando Camaleon DB Port...
english.MariaDBHint=If MariaDB is not already installed, Setup will install MariaDB 10.3 from the bundled package so the importer can run.
spanish.MariaDBHint=Si MariaDB no está instalado, el instalador pondrá MariaDB 10.3 desde el paquete incluido para que el importador pueda correr.
english.LogMariaDBFound=MariaDB was found on this computer; MSI install skipped.
spanish.LogMariaDBFound=Se encontró MariaDB en este equipo; se omite el MSI.
english.LogMariaDBWillInstall=MariaDB was not found; it will be installed.
spanish.LogMariaDBWillInstall=No se encontró MariaDB; se instalará.
english.LogDone=Installation completed successfully.
spanish.LogDone=Instalación completada correctamente.
english.InfoBefore=Camaleon DB Port copies MyISAM store tables into a named SQLite seed for Camaleon POS.%n%nThe installer also sets up Visual C++ runtime and MariaDB 10.3 when needed.
spanish.InfoBefore=Camaleon DB Port copia tablas MyISAM de tienda a un SQLite con el nombre de la base para Camaleon POS.%n%nEl instalador también configura el runtime de Visual C++ y MariaDB 10.3 si hace falta.

[Tasks]
Name: "verbose"; Description: "{cm:TaskVerbose}"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"
Name: "startmenuicon"; Description: "{cm:TaskStartMenuIcon}"

[Dirs]
Name: "{app}"; Permissions: users-modify
Name: "{app}\data"; Permissions: users-modify
Name: "{app}\data\flutter_assets"; Permissions: users-modify

[InstallDelete]
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}"

[Files]
; Main Flutter desktop binary
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; DLLs next to the EXE
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; Flutter/data assets
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

; From thirdparty\
Source: "thirdparty\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "thirdparty\mariadb-10.3.16-win32.msi"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; \
  Tasks: startmenuicon
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; \
  Tasks: desktopicon
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; Tasks: startmenuicon

[Run]
Filename: "{sys}\icacls.exe"; \
  Parameters: """{app}"" /grant *S-1-5-32-545:(OI)(CI)M /T /C"; \
  Flags: runhidden waituntilterminated; StatusMsg: "{cm:StatusGrantingPermissions}"

Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; \
  StatusMsg: "{cm:StatusInstallVCRedistX64}"; \
  Flags: waituntilterminated; Check: IsWin64

Filename: "msiexec.exe"; \
  Parameters: "/i ""{tmp}\mariadb-10.3.16-win32.msi"" /qn INSTALLDIR=""{pf32}\MariaDB 10.3"""; \
  StatusMsg: "{cm:StatusInstallMariaDB}"; \
  Flags: waituntilterminated; Check: not IsMariaDBInstalled

Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; \
  WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
var
  VerboseMode: Boolean;
  InfoPage: TOutputMsgWizardPage;

procedure LogDebug(const Msg: string);
begin
  if VerboseMode then
    Log(Msg);
end;

function FileOrDirExists(const Path: string): Boolean;
begin
  Result := FileExists(Path) or DirExists(Path);
end;

function IsMariaDBInstalled(): Boolean;
begin
  Result :=
    FileExists(ExpandConstant('{pf32}\MariaDB 10.3\bin\mysqld.exe')) or
    FileExists(ExpandConstant('{pf32}\MariaDB 10.3\bin\mysql_install_db.exe')) or
    FileExists(ExpandConstant('{pf}\MariaDB 10.3\bin\mysqld.exe')) or
    FileExists(ExpandConstant('{pf}\MariaDB 10.11\bin\mysqld.exe')) or
    FileExists(ExpandConstant('{pf}\MariaDB 11.4\bin\mysqld.exe')) or
    FileExists(ExpandConstant('{pf}\MariaDB 10.3\bin\mysqld.exe'));
end;

procedure KillRunningApp();
var
  ResultCode: Integer;
begin
  WizardForm.StatusLabel.Caption := CustomMessage('StatusStopApp');
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#MyAppExeName}',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  LogDebug('taskkill {#MyAppExeName} -> ' + IntToStr(ResultCode));
end;

function InitializeSetup(): Boolean;
begin
  VerboseMode := False;
  Result := True;
end;

procedure InitializeWizard();
begin
  InfoPage := CreateOutputMsgPage(
    wpWelcome,
    ExpandConstant('{#MyAppName}'),
    CustomMessage('InfoBefore'),
    CustomMessage('MariaDBHint'));
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = wpSelectTasks then
    VerboseMode := WizardIsTaskSelected('verbose');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    KillRunningApp();
    if IsMariaDBInstalled() then
      Log(CustomMessage('LogMariaDBFound'))
    else
      Log(CustomMessage('LogMariaDBWillInstall'));
  end;
  if CurStep = ssPostInstall then
    Log(CustomMessage('LogDone'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#MyAppExeName}',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
