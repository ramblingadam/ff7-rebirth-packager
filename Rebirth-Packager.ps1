# Read config file
$config = @{}
Get-Content 'config.ini' | ForEach-Object {
    if ($_ -match '^([^#].+?)=(.*)$') {
        $config[$matches[1].Trim()] = $matches[2].Trim()
    }
}

# Verify required settings
@('UNREALREZEN_DIR', 'MOD_BASE_DIR', 'GAME_DIR', 'STEAM_EXE', 'STEAM_APPID') | ForEach-Object {
    if (-not $config.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($config[$_])) {
        Write-Host "Error: $_ not set in config.ini"
        exit 1
    }
}

# Get current timestamp for directory naming
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# Function to update config file
function Update-Config {
    param($key, $value)
    $content = Get-Content 'config.ini' -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    [System.IO.File]::WriteAllText("$PWD\config.ini", $content)
}

# Function to draw the menu
function Show-FolderMenu {
    param($folders, $selectedIndex, $lastUsedIndex)
    Clear-Host
    Write-Host "Welcome to Tirien's Rebirth Mod Packager." -ForegroundColor Green
    Write-Host "Based on a script by Yoraiz0r <3`n" 
    Write-Host "Your mod folder should be in:" 
    Write-Host "$($config.MOD_BASE_DIR)" -ForegroundColor Yellow
    Write-Host "and contain a 'mod-content' folder which includes the full filepath of the assets you are modifying.`n" 
    Write-Host "Example:" 
    Write-Host "$($config.MOD_BASE_DIR)\cloud-green-hair\mod-content\End\Content\Character\Player\PC0000_00_Cloud_Standard\Texture\[PC0000_00_Hair_C.uasset, PC0000_00_Hair_C.ubulk]`n" -ForegroundColor Yellow
    Write-Host "Select a mod folder using arrow keys (UP/DOWN) and press Enter to confirm:" 
    Write-Host "Press Escape to cancel and enter a name manually`n"
    
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
                    $selectedIndex = [Math]::Max(0, $selectedIndex - 1)
                }
                40 { # Down arrow
                    $selectedIndex = [Math]::Min($maxIndex, $selectedIndex + 1)
                }
                13 { # Enter
                    return $folders[$selectedIndex]
                }
                27 { # Escape
                    return $null
                }
            }
        }
    }
    return $null
}

# Main script
Write-Host "Welcome to Tirien's Rebirth Mod Packager."
Write-Host "Based on a script by Yoraiz0r.`n"

# Get mod folder from arguments or prompt
$modFolder = if ($args.Count -gt 0) { $args[0] } else { Get-ModFolder }

if (-not $modFolder) {
    $promptMsg = "Enter mod folder name"
    if ($config.LAST_USED_MOD_FOLDER) {
        $promptMsg += " (or press Enter to use $($config.LAST_USED_MOD_FOLDER))"
    }
    
    $modFolder = Read-Host -Prompt $promptMsg
    
    if (-not $modFolder -and $config.LAST_USED_MOD_FOLDER) {
        $modFolder = $config.LAST_USED_MOD_FOLDER
        Write-Host "Using last used mod folder: $modFolder"
    }
}

if (-not $modFolder) {
    Write-Host "No mod folder specified and no last used folder available."
    exit 1
}

# Set content path and verify it exists
$contentPath = Join-Path $config.MOD_BASE_DIR "$modFolder\mod-content"
if (-not (Test-Path $contentPath)) {
    Write-Host "Error: Mod content path not found:"
    Write-Host $contentPath
    exit 1
}

# Update last used folder in config
Update-Config "LAST_USED_MOD_FOLDER" $modFolder

# Convert dash-case to camelCase
$modName = ($modFolder -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }) -join ''

# Create timestamped export directory
$exportDir = Join-Path $config.MOD_BASE_DIR "$modFolder\exported-$timestamp"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# Set file paths
$exportUtoc = Join-Path $exportDir "${modName}_P.utoc"
$exportUcas = Join-Path $exportDir "${modName}_P.ucas"
$exportPak = Join-Path $exportDir "${modName}_P.pak"

Write-Host "`nUsing Mod Name: $modName"
Write-Host "Content Path: $contentPath"
Write-Host "Export Directory: $exportDir`n"
Start-Sleep -Seconds 2

Write-Host "Exporting mod files to: $exportDir`n"

# Run UnrealReZen
Push-Location $config.UNREALREZEN_DIR
$unrealReZenArgs = @(
    "--content-path", $contentPath,
    "--compression-format", "Zlib",
    "--engine-version", "GAME_UE4_26",
    "--game-dir", $config.GAME_DIR,
    "--output-path", $exportUtoc
)
& "./UnrealReZen.exe" $unrealReZenArgs
$unrealReZenExitCode = $LASTEXITCODE
Pop-Location

if ($unrealReZenExitCode -eq 0) {
    # Write UCAS header exactly as in batch script
    $fs = New-Object IO.FileStream($exportUcas, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite)
    $header = [byte[]]@(0x8C, 0x06, 0x00, 0x30, 0xDE, 0x88, 0x30, 0xDC, 0x0C, 0xF0)
    $fs.Write($header, 0, $header.Length)
    $fs.Close()
    Start-Sleep -Seconds 1

    Write-Host "`nMod files have been exported to:"
    Write-Host $exportDir

    # Create zip file
    Compress-Archive -Path (Join-Path $exportDir "*_P.*") -DestinationPath (Join-Path $exportDir "$modName.zip") -Force
    Write-Host "Zip file created:"
    Write-Host $exportDir\$modName.zip

    # Ask user if they want to install mod and launch game
    $response = Read-Host "Would you like to test the mod now? (Y/N): "
    if ($response -eq 'Y' -or $response -eq 'y') {
        # Clean up previous versions of this mod
        Write-Host "`nCleaning up previous versions..."
        Get-ChildItem -Path $config.GAME_DIR -Directory | Where-Object { 
            $_.Name -like "$modName-*" 
        } | ForEach-Object {
            Write-Host "Removing: $($_.FullName)"
            Remove-Item $_.FullName -Recurse -Force
        }

        # Copy files to game directory
        $gamePakDir = Join-Path $config.GAME_DIR "$modName-$timestamp"
        if (-not (Test-Path $gamePakDir)) {
            New-Item -ItemType Directory -Path $gamePakDir -Force | Out-Null
        }

        Write-Host "`nCopying files to game directory:"
        Write-Host $gamePakDir
        Copy-Item -Path $exportUtoc -Destination $gamePakDir -Force
        Copy-Item -Path $exportUcas -Destination $gamePakDir -Force
        Copy-Item -Path $exportPak -Destination $gamePakDir -Force
        Write-Host "Files copied successfully`n"

        # Launch game and exit
        Write-Host "Launching game..."
        Start-Process $config.STEAM_EXE -ArgumentList "-applaunch", $config.STEAM_APPID
        Write-Host "`nExiting in 3 seconds..."
        Start-Sleep -Seconds 3
        exit 0
    } 
} else {
    Write-Host "Error: UnrealReZen failed to export the mod files."
    exit 1
}
