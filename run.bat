@echo off
rem Compile source\**\*.md into output\**\*.pdf (see work\md2pdf.ps1)
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0work\md2pdf.ps1"
set RC=%ERRORLEVEL%
rem Pause only when launched by double-click from Explorer (set MD2PDF_NOPAUSE=1 to disable)
if not defined MD2PDF_NOPAUSE echo %CMDCMDLINE% | find /i "/c" >nul && pause
exit /b %RC%
