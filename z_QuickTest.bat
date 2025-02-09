@echo off

set "MOD_NAME=TifaBeachHairRedBlack"
set "UNREALREZEN_DIR=D:\Everything\projects\ff7-rebirth-modding\tools\UnrealReZen_V01"
set "CONTENT_PATH=D:\Everything\projects\ff7-rebirth-modding\my-mods\tifa-beach-hair-red-black\mod-content"
set "GAME_DIR=C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY VII REBIRTH\End\Content\Paks"
set "STEAM_EXE=C:\Program Files (x86)\Steam\steam.exe"
set "STEAM_APPID=2909400"

rem FROM HERE ITS ALL AUTOMATED
rem -------------------------------

set "UTOC_FILE=%GAME_DIR%\%MOD_NAME%_P.utoc"
set "UCAS_FILE=%GAME_DIR%\%MOD_NAME%_P.ucas"
set "PAK_FILE=%GAME_DIR%\%MOD_NAME%_P.pak"

del /q "%UTOC_FILE%" 2>nul
del /q "%UCAS_FILE%" 2>nul
del /q "%PAK_FILE%" 2>nul

cd /d "%UNREALREZEN_DIR%"
UnrealReZen.exe ^
  --content-path "%CONTENT_PATH%" ^
  --compression-format Zlib ^
  --engine-version GAME_UE4_26 ^
  --game-dir "%GAME_DIR%" ^
  --output-path "%UTOC_FILE%"

powershell -Command ^
  $file = '%UCAS_FILE%'; ^
  [byte[]]$header = 0x8C,0x06,0x00,0x30,0xDE,0x88,0x30,0xDC,0x0C,0xF0; ^
  $fs = New-Object IO.FileStream($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite); ^
  $fs.Write($header,0,$header.Length); ^
  $fs.Close(); ^
  Start-Sleep -Seconds 1


timeout /t 1 /nobreak >nul

"%STEAM_EXE%" -applaunch %STEAM_APPID%
