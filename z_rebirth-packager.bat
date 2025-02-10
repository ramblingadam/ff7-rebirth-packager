@echo off
setlocal EnableDelayedExpansion

rem Load configuration from config.ini
if not exist "config.ini" (
    echo Error: config.ini not found!
    echo Please ensure config.ini exists in the same directory as this script.
    exit /b 1
)

rem Read config.ini, skipping comment lines
for /f "usebackq tokens=1,* delims==" %%a in ("config.ini") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" (
        set "%%a=%%b"
    )
)

rem Verify required settings are loaded
if not defined UNREALREZEN_DIR (
    echo Error: UNREALREZEN_DIR not set in config.ini
    exit /b 1
)
if not defined MOD_BASE_DIR (
    echo Error: MOD_BASE_DIR not set in config.ini
    exit /b 1
)
if not defined GAME_DIR (
    echo Error: GAME_DIR not set in config.ini
    exit /b 1
)
if not defined STEAM_EXE (
    echo Error: STEAM_EXE not set in config.ini
    exit /b 1
)
if not defined STEAM_APPID (
    echo Error: STEAM_APPID not set in config.ini
    exit /b 1
)

rem Get current timestamp for directory naming
for /f "usebackq tokens=1" %%a in (`powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "TIMESTAMP=%%a"

echo Welcome to Tirien's Rebirth Mod Packager.
echo Based on a script by Yoraiz0r.
echo.

rem Get mod folder from command line or prompt for input
if not "%~1"=="" (
    set "MOD_FOLDER=%~1"
) else (
    echo Your mod folder should be in:
    echo %MOD_BASE_DIR%
    echo and contain a 'mod-content' folder which includes the full filepath of the assets you are modifying.
    echo.
    echo Example:
    echo %MOD_BASE_DIR%\cloud-green-hair\mod-content\End\Content\Character\Player\PC0000_00_Cloud_Standard\Texture\[PC0000_00_Hair_C.uasset, PC0000_00_Hair_C.ubulk]
    echo.

 set "PROMPT_MSG=Enter mod folder name"
 if defined LAST_USED_MOD_FOLDER set "PROMPT_MSG=!PROMPT_MSG! (or press Enter to use !LAST_USED_MOD_FOLDER!)"

:prompt_loop
if "!INPUT_FOLDER!"=="" (
    set /p "INPUT_FOLDER=!PROMPT_MSG!: "
    if "!INPUT_FOLDER!"=="" if defined LAST_USED_MOD_FOLDER (
        set "INPUT_FOLDER=%LAST_USED_MOD_FOLDER%"
        goto :use_last_used
    )
    goto :prompt_loop
)
:use_last_used
    if "!INPUT_FOLDER!"=="" (
        set "MOD_FOLDER=%LAST_USED_MOD_FOLDER%"
    ) else (
        set "MOD_FOLDER=!INPUT_FOLDER!"
    )
)

rem Update LAST_USED_MOD_FOLDER in config.ini
powershell -ExecutionPolicy Bypass -File update_config.ps1 "%MOD_FOLDER%"

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
echo Cleaning up previous test folders from game directory...
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
