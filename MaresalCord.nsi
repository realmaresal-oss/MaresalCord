; MaresalCord Setup
; NSIS Installer Script
; Patches Discord with MaresalCord modifications
; No admin rights required, standalone executable

!include "MUI2.nsh"
!include "x64.nsh"

; Product information
Name "MaresalCord"
!define PRODUCT_NAME "MaresalCord"
!define PRODUCT_VERSION "1.15.10"
!define PRODUCT_PUBLISHER "MaresalCord"
!define PRODUCT_WEB_SITE "https://github.com/Maresal/MaresalCord"

; Installer file output
OutFile "MaresalCordSetup.exe"

; Default installation directory
InstallDir "$APPDATA\MaresalCord"

; Require user privileges (not admin)
RequestExecutionLevel user

; MUI Settings
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Language
!insertmacro MUI_LANGUAGE "English"

; Installer sections

Section "Install MaresalCord"
  SetOutPath "$INSTDIR"
  
  ; Create dist directory structure
  CreateDirectory "$INSTDIR\dist"
  CreateDirectory "$INSTDIR\dist\Installer"
  
  ; Extract core patcher files
  DetailPrint "Extracting patcher files..."
  SetOutPath "$INSTDIR\dist"
  File "dist\patcher.js"
  File "dist\renderer.js"
  File "dist\preload.js"
  File "dist\renderer.css"
  
  ; Extract installer binary
  DetailPrint "Extracting Discord injection engine..."
  SetOutPath "$INSTDIR\dist\Installer"
  File "dist\Installer\VencordInstallerCli.exe"
  
  ; Extract license
  DetailPrint "Extracting license..."
  SetOutPath "$INSTDIR"
  File "LICENSE"
  
  ; Verify extraction
  DetailPrint "Verifying installation..."
  ${If} ${FileExists} "$INSTDIR\dist\patcher.js"
    DetailPrint "✓ Patcher files verified"
  ${Else}
    MessageBox MB_OK "Error: Patcher files not found after extraction.$\n$\nSetup cannot continue."
    SetErrors
    Abort
  ${EndIf}
  
  ${If} ${FileExists} "$INSTDIR\dist\Installer\VencordInstallerCli.exe"
    DetailPrint "✓ Injection engine verified"
  ${Else}
    MessageBox MB_OK "Error: Injection engine not found after extraction.$\n$\nSetup cannot continue."
    SetErrors
    Abort
  ${EndIf}
  
  ; Check if Discord is installed
  DetailPrint "Checking for Discord installation..."
  ${If} ${FileExists} "$APPDATA\Local\Discord*"
    DetailPrint "✓ Discord detected"
  ${ElseIf} ${FileExists} "$APPDATA\Local\DiscordCanary*"
    DetailPrint "✓ Discord Canary detected"
  ${ElseIf} ${FileExists} "$APPDATA\Local\DiscordPTB*"
    DetailPrint "✓ Discord PTB detected"
  ${Else}
    MessageBox MB_OK "Discord not found.$\n$\nPlease install Discord before proceeding.$\n$\nDownload: https://discord.com/download"
    SetErrors
    Abort
  ${EndIf}
  
  ; Run VencordInstallerCli to patch Discord
  DetailPrint ""
  DetailPrint "Preparing to patch Discord..."
  DetailPrint ""
  
  ; Set environment variable for patcher location
  ; NSIS ExecWait doesn't directly support env var setting, so we use command prompt wrapper
  DetailPrint "Launching Discord patcher..."
  
  ; Create temporary batch file to set environment and run installer
  FileOpen $0 "$INSTDIR\run_installer.cmd" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 "setlocal enabledelayedexpansion$\r$\n"
  FileWrite $0 "set VENCORD_USER_DATA_DIR=$APPDATA\MaresalCord$\r$\n"
  FileWrite $0 '"$INSTDIR\dist\Installer\VencordInstallerCli.exe" -install$\r$\n'
  FileWrite $0 "set INSTALLER_EXIT_CODE=!ERRORLEVEL!$\r$\n"
  FileWrite $0 "exit /b !INSTALLER_EXIT_CODE!$\r$\n"
  FileClose $0
  
  ; Execute the installer
  ExecWait '"$INSTDIR\run_installer.cmd"' $0
  
  ; Clean up temporary batch file
  ${If} ${FileExists} "$INSTDIR\run_installer.cmd"
    Delete "$INSTDIR\run_installer.cmd"
  ${EndIf}
  
  ; Check exit code
  DetailPrint ""
  ${If} $0 == 0
    DetailPrint "✓ Discord patch successful"
    DetailPrint ""
    DetailPrint "MaresalCord has been successfully installed!"
    DetailPrint "Discord will load MaresalCord modifications on next launch."
  ${ElseIf} $0 == 5
    ; Exit code 5 often means "Access Denied"
    MessageBox MB_OKCANCEL "Discord patching failed: Permission denied.$\n$\nThis can happen if:$\n- Discord is currently running (please close it)$\n- Your Discord is installed system-wide$\n$\nWould you like to retry?" IDOK retry IDCANCEL abort
    retry:
      MessageBox MB_OK "Please close Discord completely and run Setup again."
      Goto abort
    abort:
      SetErrors
      Abort
  ${Else}
    MessageBox MB_OK "Discord patching failed with error code: $0$\n$\nPlease ensure:$\n- Discord is installed$\n- Discord is not currently running$\n- You have write permissions to your Discord files"
    SetErrors
    Abort
  ${EndIf}
  
  ; Create uninstaller
  DetailPrint ""
  DetailPrint "Creating uninstaller..."
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Write installation info to registry (for Add/Remove Programs)
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord" \
    "DisplayName" "MaresalCord"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord" \
    "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord" \
    "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord" \
    "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord" \
    "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord" \
    "InstallLocation" "$INSTDIR"
  
  DetailPrint "✓ Installation complete"
SectionEnd

; Uninstaller section
Section "Uninstall"
  DetailPrint "Removing MaresalCord files..."
  
  ; Remove MaresalCord installation files
  Delete "$INSTDIR\dist\patcher.js"
  Delete "$INSTDIR\dist\renderer.js"
  Delete "$INSTDIR\dist\preload.js"
  Delete "$INSTDIR\dist\renderer.css"
  Delete "$INSTDIR\dist\Installer\VencordInstallerCli.exe"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\Uninstall.exe"
  
  ; Remove directories
  RMDir "$INSTDIR\dist\Installer"
  RMDir "$INSTDIR\dist"
  RMDir "$INSTDIR"
  
  ; Remove registry entries
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MaresalCord"
  
  DetailPrint "✓ Uninstallation complete"
  DetailPrint ""
  DetailPrint "MaresalCord has been uninstalled."
  DetailPrint "Note: Discord modifications remain. Run Discord normally to use vanilla Discord,"
  DetailPrint "or reinstall MaresalCord to restore modifications."
SectionEnd

; Function to handle installation on init
Function .onInit
  ; Check Windows version
  ${If} ${RunningX64}
    DetailPrint "Running on Windows 64-bit"
  ${Else}
    DetailPrint "Running on Windows 32-bit"
  ${EndIf}
  
  ; Check if already installed
  ${If} ${FileExists} "$INSTDIR\dist\patcher.js"
    MessageBox MB_OKCANCEL "MaresalCord appears to be already installed at:$\n$INSTDIR$\n$\nDo you want to continue with reinstallation?" IDOK continue IDCANCEL abort
    continue:
      ; Continue with installation
    abort:
      Abort
  ${EndIf}
FunctionEnd

; Function to handle uninstall on init
Function un.onInit
  MessageBox MB_OKCANCEL "Are you sure you want to uninstall MaresalCord?$\n$\nNote: Discord modifications will be removed, but Discord itself will not be uninstalled." IDOK continue IDCANCEL abort
  continue:
    ; Continue with uninstallation
  abort:
    Abort
FunctionEnd

; Function to handle finish
Function .onInstSuccess
  ; Optionally launch Discord
  MessageBox MB_YESNO "MaresalCord installation successful!$\n$\nWould you like to launch Discord now?" IDNO skip IDYES launch
  launch:
    Exec "$APPDATA\Local\Discord\DiscordCanary.exe"
  skip:
    ; Just close installer
FunctionEnd
