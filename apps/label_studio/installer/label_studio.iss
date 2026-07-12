; Script Inno Setup para gerar um pacote PORTÁTIL do label_studio.
; Não instala o app (sem entradas no registro, sem Add/Remove Programs,
; sem exigir admin): apenas extrai os arquivos da build Release para a
; pasta escolhida pelo usuário.
;
; Pré-requisito: gerar a build antes de compilar este script.
;   cd apps\label_studio
;   flutter build windows --release
;
; Compilação (via ISCC.exe do Inno Setup, ou abrindo este arquivo no IDE):
;   iscc installer\label_studio.iss
;
; O instalador final é gerado em apps\label_studio\dist\, com a versão
; (lida diretamente do .exe compilado, que por sua vez vem do
; pubspec.yaml) no nome do arquivo.

#define MyAppName "Label Studio"
#define MyAppPublisher "JoeLabs"
#define MyAppExeName "label_studio.exe"
#define ReleaseDir "..\build\windows\x64\runner\Release"
#define MyAppExePath ReleaseDir + "\" + MyAppExeName

#if !FileExists(MyAppExePath)
  #error "Build Release nao encontrada. Rode 'flutter build windows --release' dentro de apps\label_studio antes de compilar este instalador."
#endif

; ProductVersion vem no formato do pubspec.yaml (ex.: "1.0.0+1"); o
; instalador usa só a parte semântica ("1.0.0") no nome do arquivo.
#define MyFullVersion GetStringFileInfo(MyAppExePath, "ProductVersion")
#define MyPlusPos Pos("+", MyFullVersion)
#if MyPlusPos > 0
  #define MyAppVersion Copy(MyFullVersion, 1, MyPlusPos - 1)
#else
  #define MyAppVersion MyFullVersion
#endif

[Setup]
AppId={{B36E2C1F-6E7C-4E0F-9E9F-0B7C6C2A2B6C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={userdocs}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=no
DisableReadyPage=yes
DisableWelcomePage=no
Uninstallable=no
CreateUninstallRegKey=no
PrivilegesRequired=lowest
UsePreviousAppDir=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
OutputDir=..\dist
OutputBaseFilename=label_studio_portable_v{#MyAppVersion}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
