; This is for Vista. For some reason it is not reading
; my template correctly.

!include "MUI.nsh"
!define VERSION "2.7.2"
!define NAME "OSPatrol"
!define /date CDATE "%b %d %Y at %H:%M:%S"


Name "${NAME} Windows Agent v${VERSION}"
BrandingText "Copyright (C) 2013 Trend Micro Inc."
OutFile "win32ui.exe"


InstallDir $PROGRAMFILES\ospatrol-agent


  !define MUI_ICON favicon.ico


  !insertmacro MUI_LANGUAGE "English"

;--------------------------------

Function .onInit
    SetOutPath $INSTDIR
    Exec '"$INSTDIR\os_win32ui.exe" "$INSTDIR"'
    Abort
FunctionEnd



Section "OSPatrol UI - Should not be called." MainSec
;Required section.
SectionIn RO
SectionEnd
