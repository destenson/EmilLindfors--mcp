; mcp-rs Installer Script
; Created with NSIS

; Define constants
!define PRODUCT_NAME "mcp-rs tools"
!define PRODUCT_VERSION "0.1.0"
!define PRODUCT_PUBLISHER "mcp-rs Contributors"
!define PRODUCT_WEB_SITE "https://github.com/EmilLindfors/mcp"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\mcp-rs.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Basic installer settings
SetCompressor lzma
RequestExecutionLevel admin

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\mcp-rs-setup.exe"
InstallDir "$PROGRAMFILES\mcp-rs"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer

  ; Add files to install
  File "dist\mcp-rs-client.exe"
  File "dist\mcp-rs-server.exe"
  File "..\LICENSE"
  File "..\README.md"

  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\mcp-rs"
  CreateShortCut "$SMPROGRAMS\mcp-rs\mcp-rs.lnk" "$INSTDIR\mcp-rs.exe"
  CreateShortCut "$DESKTOP\mcp-rs.lnk" "$INSTDIR\mcp-rs.exe"
SectionEnd

Section -AdditionalIcons
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\mcp-rs\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\mcp-rs\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\mcp-rs.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\mcp-rs.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

; Add environment variable section
Section "Environment Variables" SEC02
  ; Add mcp-rs to PATH
  Push "$INSTDIR"
  Call AddToPath
SectionEnd

; Uninstaller sections
Section "Uninstall"
  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\mcp-rs\Uninstall.lnk"
  Delete "$SMPROGRAMS\mcp-rs\Website.lnk"
  Delete "$DESKTOP\mcp-rs.lnk"
  Delete "$SMPROGRAMS\mcp-rs\mcp-rs.lnk"
  RMDir "$SMPROGRAMS\mcp-rs"

  ; Remove files and uninstaller
  Delete "$INSTDIR\${PRODUCT_NAME}.url"
  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\mcp-rs.exe"
  Delete "$INSTDIR\mcp-rs-client.exe"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\README.md"

  ; Remove directories used
  RMDir "$INSTDIR"

  ; Remove registry keys
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

  ; Remove from PATH
  Push "$INSTDIR"
  Call un.RemoveFromPath

  SetAutoClose true
SectionEnd

; Path manipulation functions
!define Environ 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

; AddToPath - Adds the given dir to the PATH environment variable
;   Input: head of the stack contains the dir to add
Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3

  ; Get the current PATH
  ReadRegStr $1 ${Environ} "PATH"

  ; Check if the directory is already in PATH
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" 0 AddToPath_done

  ; Append the new directory to PATH
  StrCpy $2 $1 1 -1
  StrCmp $2 ";" 0 +2
  StrCpy $1 $1 -1 ; remove trailing semicolon if present
  StrCmp $1 "" AddToPath_NoPreviousPath
  StrCpy $0 "$1;$0"
  Goto AddToPath_Done

  AddToPath_NoPreviousPath:
  StrCpy $0 "$0"

  AddToPath_Done:
  WriteRegExpandStr ${Environ} "PATH" $0
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

; RemoveFromPath - Removes the given dir from the PATH environment variable
;   Input: head of the stack contains the dir to remove
Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6

  ; Get the current PATH
  ReadRegStr $1 ${Environ} "PATH"

  ; Construct the new PATH
  StrCpy $5 $1 1 -1
  StrCmp $5 ";" +2
  StrCpy $1 "$1;" ; append semicolon if missing
  Push $1
  Push "$0;"
  Call un.StrStr
  Pop $2 ; $2 now contains the part of the path before our dir
  StrLen $3 "$0;"
  StrLen $4 $2
  StrCpy $5 $1 "" $4 ; $5 now contains the part of the path after our dir
  StrCmp $2 "" RemoveFromPath_done
  StrCmp $5 "" RemoveFromPath_done
  StrCpy $6 $2 -1 ; remove trailing semicolon from the part before
  StrCpy $1 "$6$5"

  RemoveFromPath_done:
  WriteRegExpandStr ${Environ} "PATH" $1
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

; StrStr - Find a substring in a string
;   Input: top of stack = string to search for
;          top of stack-1 = string to search in
;   Output: top of stack = search result (empty if not found)
Function StrStr
  Exch $R1 ; search string
  Exch
  Exch $R2 ; source string
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1 = search string, $R2 = source string
  ; $R3 = search string length, $R4 = source position
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
  done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd

; Same as StrStr but for uninstaller
Function un.StrStr
  Exch $R1 ; search string
  Exch
  Exch $R2 ; source string
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1 = search string, $R2 = source string
  ; $R3 = search string length, $R4 = source position
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
  done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd

; Define constants for Windows messages
!define HWND_BROADCAST 0xFFFF
!define WM_WININICHANGE 0x001A
