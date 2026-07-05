@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0preparar_cliente.ps1"
if errorlevel 1 (
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ligar_servidor.ps1"
if errorlevel 1 (
    pause
    exit /b 1
)

set "MINIMAP_DIR=%LOCALAPPDATA%\Tibia\packages\Tibia\minimap"
if not exist "%MINIMAP_DIR%" mkdir "%MINIMAP_DIR%"

copy /Y "minimap\minimapmarkers.bin" "%MINIMAP_DIR%\" >nul 2>nul
copy /Y "minimap\Minimap_Color_*.png" "%MINIMAP_DIR%\" >nul 2>nul
copy /Y "minimap\Minimap_WaypointCost_*.png" "%MINIMAP_DIR%\" >nul 2>nul

start "" "%~dp0bin\client-local.exe"
endlocal
exit /b 0
