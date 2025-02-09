@echo off
setlocal EnableDelayedExpansion

rem ===== MANUAL MOD FOLDER SETTING =====
rem Set this if not using command line argument
set "DEFAULT_MOD_FOLDER=tifa-gothic-makeup-purple-lipstick"
rem ====================================

rem Set static paths
set "UNREALREZEN_DIR=D:\Everything\projects\ff7-rebirth-modding\tools\UnrealReZen_V01"
set "MOD_BASE_DIR=D:\Everything\projects\ff7-rebirth-modding\my-mods"
set "GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY VII REBIRTH\End\Content\Paks"
set "STEAM_EXE=C:\Program Files (x86)\Steam\steam.exe"
set "STEAM_APPID=2909400"

rem Get current timestamp for directory naming
for /f "usebackq tokens=1" %%a in (`powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "TIMESTAMP=%%a"

rem Get mod folder from command line or default
if not "%~1"=="" (
    set "MOD_FOLDER=%~1"
) else (
    set /p "INPUT_FOLDER=Enter mod folder name (or press Enter to use default): "
    if "!INPUT_FOLDER!"=="" (
        if "%DEFAULT_MOD_FOLDER%"=="" (
            echo Error: No mod folder specified and no default set.
            echo Usage: %~nx0 [mod-folder-name]
            echo Example: %~nx0 tifa-beach-hair-red-black
            exit /b 1
        )
        
        echo Using default mod folder: %DEFAULT_MOD_FOLDER%
        echo.
        set /p "CONFIRM=Continue with this mod folder? (Y/N): "
        if /i not "!CONFIRM!"=="Y" (
            echo Operation cancelled by user.
            exit /b 1
        )
        set "MOD_FOLDER=%DEFAULT_MOD_FOLDER%"
    ) else (
        set "MOD_FOLDER=!INPUT_FOLDER!"
    )
)

rem Set content path and verify it exists
set "CONTENT_PATH=%MOD_BASE_DIR%\%MOD_FOLDER%\mod-content"
if not exist "%CONTENT_PATH%" (
    echo Error: Mod content path not found:
    echo %CONTENT_PATH%
    exit /b 1
)

rem Convert dash-case to camelCase using PowerShell
for /f "usebackq delims=" %%a in (`powershell -Command "$words = '%MOD_FOLDER%' -split '-'; $result = foreach($word in $words) { $word.Substring(0,1).ToUpper() + $word.Substring(1).ToLower() }; $result -join ''"`) do set "MOD_NAME=%%a"

rem Create timestamped export directory
set "EXPORT_DIR=%MOD_BASE_DIR%\%MOD_FOLDER%\exported_%TIMESTAMP%"
if not exist "%EXPORT_DIR%" mkdir "%EXPORT_DIR%"

rem Set file paths for both export and game directories
set "EXPORT_UTOC=%EXPORT_DIR%\%MOD_NAME%_P.utoc"
set "EXPORT_UCAS=%EXPORT_DIR%\%MOD_NAME%_P.ucas"
set "EXPORT_PAK=%EXPORT_DIR%\%MOD_NAME%_P.pak"

echo.
echo Using Mod Name: %MOD_NAME%
echo Content Path: %CONTENT_PATH%
echo Export Directory: %EXPORT_DIR%
echo.
timeout /t 2 /nobreak >nul

rem FROM HERE ITS ALL AUTOMATED
rem -------------------------------

echo Exporting mod files to: %EXPORT_DIR%
echo.

cd /d "%UNREALREZEN_DIR%"
UnrealReZen.exe ^
  --content-path "%CONTENT_PATH%" ^
  --compression-format Zlib ^
  --engine-version GAME_UE4_26 ^
  --game-dir "%GAME_DIR%" ^
  --output-path "%EXPORT_UTOC%"

powershell -Command ^
  $file = '%EXPORT_UCAS%'; ^
  [byte[]]$header = 0x8C,0x06,0x00,0x30,0xDE,0x88,0x30,0xDC,0x0C,0xF0; ^
  $fs = New-Object IO.FileStream($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite); ^
  $fs.Write($header,0,$header.Length); ^
  $fs.Close(); ^
  Start-Sleep -Seconds 1

echo.
echo Mod files have been exported to: %EXPORT_DIR%

rem Create zip file of the exported files
echo Creating zip archive...
powershell -Command ^
  Compress-Archive -Path '%EXPORT_DIR%\*_P.*' -DestinationPath '%EXPORT_DIR%\%MOD_NAME%.zip' -Force

echo Zip file created: %EXPORT_DIR%\%MOD_NAME%.zip
echo.
set /p "TEST_MOD=Would you like to test the mod now? (Y/N): "
if /i not "!TEST_MOD!"=="Y" (
    echo Export complete. Exiting without testing.
    exit /b 0
)

rem Copy files to game directory for testing
echo.
echo Cleaning up previous test folders...
for /d %%i in ("%GAME_DIR%\%MOD_NAME%_*") do rd /s /q "%%i"

echo Copying mod files to game directory...
set "GAME_MOD_DIR=%GAME_DIR%\%MOD_NAME%_%TIMESTAMP%"
if not exist "%GAME_MOD_DIR%" mkdir "%GAME_MOD_DIR%"

copy /y "%EXPORT_UTOC%" "%GAME_MOD_DIR%\%MOD_NAME%_P.utoc" >nul
copy /y "%EXPORT_UCAS%" "%GAME_MOD_DIR%\%MOD_NAME%_P.ucas" >nul
copy /y "%EXPORT_PAK%" "%GAME_MOD_DIR%\%MOD_NAME%_P.pak" >nul

echo.
echo Launching game...
timeout /t 1 /nobreak >nul
"%STEAM_EXE%" -applaunch %STEAM_APPID%
