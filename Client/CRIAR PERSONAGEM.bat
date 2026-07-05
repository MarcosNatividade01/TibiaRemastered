@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ligar_servidor.ps1"
if errorlevel 1 (
    pause
    exit /b 1
)

start "" "%~dp0bin\client-local.exe"
endlocal
exit /b 0
