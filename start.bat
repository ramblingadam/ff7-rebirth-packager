@echo off
setlocal EnableDelayedExpansion

rem Launch PowerShell script with bypass to avoid execution policy issues
powershell -ExecutionPolicy Bypass -File "%~dp0Rebirth-Packager.ps1"

rem If PowerShell exits with an error, pause to show the error
if errorlevel 1 (
    echo.
    echo An error occurred. Press any key to exit...
    pause >nul
    exit /b 1
)
