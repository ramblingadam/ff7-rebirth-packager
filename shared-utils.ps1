# Function to draw the menu
function Show-FolderMenu {
    param($folders, $selectedIndex, $lastUsedIndex, $title = "Mod Folder Selection")
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|            $title            |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow

    Write-Host "Select a mod folder using arrow keys (UP/DOWN) and press Enter to confirm" -ForegroundColor Cyan
    Write-Host "(Or press 'C' to open configuration setup)`n" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $folders.Count; $i++) {
        $prefix = if ($i -eq $selectedIndex) { "-> " } else { "   " }
        $suffix = if ($i -eq $lastUsedIndex) { " (last used)" } else { "" }
        if ($i -eq $selectedIndex) {
            Write-Host "$prefix$($folders[$i])$suffix" -ForegroundColor Green
        } else {
            Write-Host "$prefix$($folders[$i])$suffix"
        }
    }
}

# Function to get mod folder selection
function Get-ModFolder {
    param($config)
    $folders = Get-ChildItem -Path $config.MOD_BASE_DIR -Directory | Select-Object -ExpandProperty Name
    
    if ($folders.Count -gt 0) {
        # Find index of last used folder
        $selectedIndex = 0
        $lastUsedIndex = -1
        if ($config.LAST_USED_MOD_FOLDER) {
            $lastUsedIndex = [array]::IndexOf($folders, $config.LAST_USED_MOD_FOLDER)
            if ($lastUsedIndex -ge 0) {
                $selectedIndex = $lastUsedIndex
            }
        }
        
        $maxIndex = $folders.Count - 1

        while ($true) {
            Show-FolderMenu $folders $selectedIndex $lastUsedIndex

            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($key.VirtualKeyCode) {
                38 { # Up arrow
                    if ($selectedIndex -gt 0) { $selectedIndex-- }
                }
                40 { # Down arrow
                    if ($selectedIndex -lt $maxIndex) { $selectedIndex++ }
                }
                67 { # 'C' key
                    return "CONFIG"
                }
                13 { # Enter
                    $selectedFolder = $folders[$selectedIndex]
                    # Update last used folder in config
                    Update-Config "LAST_USED_MOD_FOLDER" $selectedFolder
                    return $selectedFolder
                }
            }
        }
    } else {
        Write-Host "No mod folders found in $($config.MOD_BASE_DIR)" -ForegroundColor Red
        return $null
    }
}

# Function to update config file
function Update-Config {
    param($key, $value)
    $configPath = Join-Path $PSScriptRoot "config.ini"
    $content = Get-Content $configPath -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    [System.IO.File]::WriteAllText($configPath, $content)
}

# Function to validate directory exists
function Test-DirectoryValid {
    param($path)
    return (Test-Path $path -PathType Container)
}

# Function to validate file exists
function Test-FileValid {
    param($path)
    return (Test-Path $path -PathType Leaf)
}

# Function to get a valid directory from user
function Get-ValidDirectory {
    param($prompt, $currentValue)
    
    while ($true) {
        Write-Host "`n$prompt" -ForegroundColor Cyan
        if ($currentValue) {
            Write-Host "Current value: " -NoNewline
            Write-Host $currentValue -ForegroundColor Green
            $input = Read-Host "Press Enter to keep current value, or enter new path"
            if ([string]::IsNullOrWhiteSpace($input)) {
                return $currentValue
            }
        } else {
            $input = Read-Host "Enter path"
        }
        
        if (Test-DirectoryValid $input) {
            return $input
        }
        Write-Host " Directory not found. Please enter a valid path." -ForegroundColor Red
    }
}

# Function to get a valid file from user
function Get-ValidFile {
    param($prompt, $currentValue)
    
    while ($true) {
        Write-Host "`n$prompt" -ForegroundColor Cyan
        if ($currentValue) {
            Write-Host "Current value: " -NoNewline
            Write-Host $currentValue -ForegroundColor Green
            $input = Read-Host "Press Enter to keep current value, or enter new path"
            if ([string]::IsNullOrWhiteSpace($input)) {
                return $currentValue
            }
        } else {
            $input = Read-Host "Enter path"
        }
        
        if (Test-FileValid $input) {
            return $input
        }
        Write-Host " File not found. Please enter a valid path." -ForegroundColor Red
    }
}

# Function to start configuration setup
function Start-ConfigSetup {
    param(
        $title = "Configuration Setup",
        $subtitle = ""
    )
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|$(' ' * [math]::Floor((41 - $title.Length) / 2))$title$(' ' * [math]::Ceiling((41 - $title.Length) / 2))|" -ForegroundColor Yellow
    if ($subtitle) {
        Write-Host "|$(' ' * [math]::Floor((41 - $subtitle.Length) / 2))$subtitle$(' ' * [math]::Ceiling((41 - $subtitle.Length) / 2))|" -ForegroundColor Yellow
    }
    Write-Host "+=========================================+`n" -ForegroundColor Yellow
    
    Write-Host "Configuration Setup" -ForegroundColor Cyan
    
    # Get mod base directory
    $config.MOD_BASE_DIR = Get-ValidDirectory "Enter mod base directory path" $config.MOD_BASE_DIR
    Update-Config "MOD_BASE_DIR" $config.MOD_BASE_DIR
    
    # Get game directory
    $config.GAME_DIR = Get-ValidDirectory "Enter game directory path" $config.GAME_DIR
    Update-Config "GAME_DIR" $config.GAME_DIR
    
    # Get Steam executable
    $config.STEAM_EXE = Get-ValidFile "Enter Steam executable path" $config.STEAM_EXE
    Update-Config "STEAM_EXE" $config.STEAM_EXE
}

# Function to package a mod and optionally launch the game
function Start-ModPackaging {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModFolder,
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        [switch]$LaunchGame = $false
    )
    
    # Get current timestamp for directory naming
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    
    # Set content path and verify it exists
    $contentPath = Join-Path $Config.MOD_BASE_DIR "$ModFolder\mod-content"
    if (-not (Test-Path $contentPath)) {
        Write-Host "Error: Mod content path not found:"
        Write-Host $contentPath
        return $false
    }
    
    # Convert dash-case to PascalCase for mod name
    $modName = ($ModFolder -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
    
    # Create timestamped export directory
    $exportDir = Join-Path $Config.MOD_BASE_DIR "$ModFolder\${modName}-$timestamp"
    New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    
    # Set file paths
    $gamePakDir = Join-Path $Config.GAME_DIR "\End\Content\Paks"
    $exportUtoc = Join-Path $exportDir "${modName}_P.utoc"
    $exportUcas = Join-Path $exportDir "${modName}_P.ucas"
    $exportPak = Join-Path $exportDir "${modName}_P.pak"
    
    Write-Host "`nUsing Mod Name: " -NoNewline -ForegroundColor Yellow
    Write-Host "$modName`n" -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # Run UnrealReZen
    $unrealRezenPath = Join-Path $PSScriptRoot "tools\UnrealReZen\UnrealReZen.exe"
    Push-Location (Split-Path $unrealRezenPath)
    $unrealReZenArgs = @(
        "--content-path", $contentPath,
        "--compression-format", "Zlib",
        "--engine-version", "GAME_UE4_26",
        "--game-dir", $gamePakDir,
        "--output-path", $exportUtoc
    )
    & "./UnrealReZen.exe" $unrealReZenArgs
    $unrealReZenExitCode = $LASTEXITCODE
    Pop-Location
    
    if ($unrealReZenExitCode -eq 0) {
        # Adjust UCAS header to be compatible with FF7 Rebirth
        $fs = New-Object IO.FileStream($exportUcas, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite)
        $header = [byte[]]@(0x8C, 0x06, 0x00, 0x30, 0xDE, 0x88, 0x30, 0xDC, 0x0C, 0xF0)
        $fs.Write($header, 0, $header.Length)
        $fs.Close()
        Start-Sleep -Seconds 1
        
        Write-Host "`nMod files have been exported to:" -ForegroundColor Yellow
        Write-Host "${exportDir}`n" -ForegroundColor Green
        
        # Create zip file
        Compress-Archive -Path (Join-Path $exportDir "*_P.*") -DestinationPath (Join-Path $exportDir "$modName.zip") -Force
        Write-Host "Zip file created:" -ForegroundColor Yellow
        Write-Host $exportDir\$modName.zip -ForegroundColor Green
        
        if ($LaunchGame) {
            Install-AndLaunchMod -ModName $modName -Timestamp $timestamp -ExportDir $exportDir -ExportUtoc $exportUtoc -ExportUcas $exportUcas -ExportPak $exportPak -Config $Config
        }
        
        return $true
    } else {
        Write-Host "Error: UnrealReZen failed to export the mod files." -ForegroundColor Red
        return $false
    }
}

# Function to install mod and launch game
function Install-AndLaunchMod {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModName,
        [Parameter(Mandatory=$true)]
        [string]$Timestamp,
        [Parameter(Mandatory=$true)]
        [string]$ExportDir,
        [Parameter(Mandatory=$true)]
        [string]$ExportUtoc,
        [Parameter(Mandatory=$true)]
        [string]$ExportUcas,
        [Parameter(Mandatory=$true)]
        [string]$ExportPak,
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    $gamePakDir = Join-Path $Config.GAME_DIR "\End\Content\Paks"
    
    # Clean up previous versions of this mod in game directory
    Write-Host "`nCleaning up previous versions in game directory..." -ForegroundColor Yellow
    Get-ChildItem -Path $gamePakDir -Directory | Where-Object { 
        $_.Name -like "$ModName-*" 
    } | ForEach-Object {
        Write-Host "Removing: $($_.FullName)"
        Remove-Item $_.FullName -Recurse -Force
        Write-Host "Removed: $($_.FullName)" -ForegroundColor Green
    }
    Start-Sleep -Seconds 1
    
    # Copy files to game directory
    $gameExportDir = Join-Path $gamePakDir "$ModName-$Timestamp"
    if (-not (Test-Path $gameExportDir)) {
        New-Item -ItemType Directory -Path $gameExportDir -Force | Out-Null
    }
    
    Write-Host "`nCopying files to game directory:" -ForegroundColor Yellow
    Copy-Item -Path $ExportUtoc -Destination $gameExportDir -Force
    Copy-Item -Path $ExportUcas -Destination $gameExportDir -Force
    Copy-Item -Path $ExportPak -Destination $gameExportDir -Force
    Write-Host "Files copied successfully`n" -ForegroundColor Green
    
    # Launch game
    Write-Host "Launching game..." -ForegroundColor Yellow
    Start-Process $Config.STEAM_EXE -ArgumentList "-applaunch", $Config.STEAM_APPID
    Start-Sleep -Seconds 3
}
