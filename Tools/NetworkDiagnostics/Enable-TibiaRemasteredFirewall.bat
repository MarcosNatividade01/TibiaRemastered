@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Enable-TibiaRemasteredFirewall.ps1" %*
pause
