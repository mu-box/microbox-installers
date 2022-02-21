#define MyAppName "Microbox"
#define MyInstallerName "MicroboxSetup"
#define MyAppPublisher "Microbox Developers"
#define MyAppURL "https://microbox.cloud"
#define MyAppContact "https://microbox.cloud"

#define microbox "..\bundle\microbox.exe"
#define microboxUpdater "..\bundle\microbox-update.exe"
#define microboxVpn "..\bundle\microbox-vpn.exe"
#define microboxMachine "..\bundle\microbox-machine.exe"
#define ansiconexe "..\bundle\ansicon.exe"
#define ansicon32 "..\bundle\ANSI32.dll"
#define ansicon64 "..\bundle\ANSI64.dll"
#define loggerdll "..\bundle\logger.dll"
#define srvstartdll "..\bundle\srvstart.dll"
#define srvstartexe "..\bundle\srvstart.exe"
#define oemvistainf "..\bundle\OemVista.inf"
#define tap0901cat "..\bundle\tap0901.cat"
#define tap0901sys "..\bundle\tap0901.sys"
#define tapinstallexe "..\bundle\tapinstall.exe"

[Setup]
AppCopyright={#MyAppPublisher}
AppId={#MyAppName}
AppContact={#MyAppContact}
AppComments={#MyAppURL}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
OutputBaseFilename={#MyInstallerName}
Compression=lzma
SolidCompression=yes
WizardImageFile=windows-installer-side.bmp
WizardSmallImageFile=windows-installer-logo.bmp
WizardImageStretch=yes
UninstallDisplayIcon={app}\unins000.exe
SetupIconFile=microbox.ico
ChangesEnvironment=true

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Tasks]
Name: modifypath; Description: "Add microbox binaries to &PATH"
Name: ansicon; Description: "Install ANSI escape sequences for console programs"

[Components]
Name: "Microbox"; Description: "Microbox for Windows" ; Types: full custom; Flags: fixed

[Files]
Source: "{#microbox}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Microbox"
Source: "{#microboxUpdater}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Microbox"
Source: "{#microboxVpn}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Microbox"
Source: "{#microboxMachine}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Microbox"
Source: "{#ansiconexe}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#ansicon32}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#ansicon64}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#loggerdll}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#srvstartdll}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#srvstartexe}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#oemvistainf}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#tap0901cat}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#tap0901sys}"; DestDir: "{app}"; Components: "Microbox"
Source: "{#tapinstallexe}"; DestDir: "{app}"; Components: "Microbox"

[UninstallRun]
Filename: "{app}\microbox.exe"; Parameters: "implode"
Filename: "{app}\ansicon.exe"; Parameters: "-U"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName:"MICROBOX_INSTALL_PATH"; ValueData:"{app}" ; Flags: preservestringtype uninsdeletevalue;

[Code]
#include "base64.iss"
#include "guid.iss"

function uuid(): String;
var
  dirpath: String;
  filepath: String;
  ansiresult: AnsiString;
begin
  dirpath := ExpandConstant('{userappdata}\Microbox');
  filepath := dirpath + '\id.txt';
  ForceDirectories(dirpath);

  Result := '';
  if FileExists(filepath) then
    LoadStringFromFile(filepath, ansiresult);
    Result := String(ansiresult)

  if Length(Result) = 0 then
    Result := GetGuid('');
    StringChangeEx(Result, '{', '', True);
    StringChangeEx(Result, '}', '', True);
    SaveStringToFile(filepath, AnsiString(Result), False);
end;

function WindowsVersionString(): String;
var
  ResultCode: Integer;
  lines : TArrayOfString;
begin
  if not Exec(ExpandConstant('{cmd}'), ExpandConstant('/c wmic os get caption | more +1 > C:\windows-version.txt'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then begin
    Result := 'N/A';
    exit;
  end;

  if LoadStringsFromFile(ExpandConstant('C:\windows-version.txt'), lines) then begin
    Result := lines[0];
  end else begin
    Result := 'N/A'
  end;
end;

procedure InitializeWizard;
var
  WelcomePage: TWizardPage;
begin

  WelcomePage := PageFromID(wpWelcome)

  WizardForm.WelcomeLabel2.AutoSize := True;
  
end;

const
  ModPathName = 'modifypath';
  ModPathType = 'user';

function ModPathDir(): TArrayOfString;
begin
  setArrayLength(Result, 1);
  Result[0] := ExpandConstant('{app}');
end;

procedure RunInstallAnsicon();
var
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing Ansicon'
  if not Exec(ExpandConstant('{app}\ansicon'), ExpandConstant('-I'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    MsgBox('ansicon install failure', mbInformation, MB_OK);
end;

procedure RunInstallTapWindows();
var
  ExecStdout: AnsiString;
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing Tap Windows Driver'
  if Exec(ExpandConstant('{cmd}'), '/C "' + ExpandConstant('"{app}\tapinstall.exe"') + ' find tap0901 > ' + ExpandConstant('"{tmp}\taplist.txt"') + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if LoadStringFromFile(ExpandConstant('{tmp}\taplist.txt'), ExecStdout) then
    begin
      if Pos('No matching devices found', String(ExecStdout)) > 0 then
      begin
        if not Exec(ExpandConstant('{app}\tapinstall.exe'), ExpandConstant('install "{app}/OemVista.inf" tap0901'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
          MsgBox('Tap install failure', mbInformation, MB_OK);
      end;
    end;
  end;
end;

#include "modpath.iss"

procedure CurStepChanged(CurStep: TSetupStep);
var
  Success: Boolean;
begin
  Success := True;
  if CurStep = ssPostInstall then
  begin
    RunInstallTapWindows();
    if isTaskSelected('ansicon') then
      RunInstallAnsicon();
    if IsTaskSelected(ModPathName) then
      ModPath();
  end;
end;
