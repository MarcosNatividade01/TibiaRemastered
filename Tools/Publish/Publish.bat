@echo off
setlocal
cd /d "%~dp0..\.."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Scripts\Test-OfficialReleaseChecklist.ps1"
if errorlevel 1 (
    echo.
    echo Publicacao cancelada: Checklist Oficial de Release falhou.
    echo Corrija os itens indicados antes de publicar.
    echo.
    pause
    endlocal
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Publish.ps1" %*
echo.
pause
endlocal
