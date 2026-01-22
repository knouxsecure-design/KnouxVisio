@echo off
TITLE TITAN ARC LAUNCHER
CHCP 65001 >NUL
COLOR 0B
CLS
ECHO.
ECHO   [ TITAN ARC SYSTEM V3.0 ]
ECHO.
SET /P T=">> TARGET: "
IF "%T%"=="" GOTO END
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "F:\KnouxVisio_Dashboard\TITAN-CORE.ps1" -Target "%T%"
:END
PAUSE
