@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_PATH=%SCRIPT_DIR%ClickByChris_Setup_Tool.ps1"

if not exist "%SCRIPT_PATH%" (
    echo Script introuvable :
    echo %SCRIPT_PATH%
    pause
    exit /b 1
)

where pwsh >nul 2>nul
if %errorlevel%==0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
)

endlocal
