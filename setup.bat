@echo off
rem Download and check the tools (bin\) and the default font (source\_fonts\).
rem Options: -NoExtension (skip the VS Code extension), -Force (download again)
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0work\setup.ps1" %*
set RC=%ERRORLEVEL%
rem Pause only when launched by double-click from Explorer (set MD2PDF_NOPAUSE=1 to disable)
if not defined MD2PDF_NOPAUSE echo %CMDCMDLINE% | find /i "/c" >nul && pause
exit /b %RC%
