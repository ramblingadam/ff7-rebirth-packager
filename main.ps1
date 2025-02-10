# Function to update config file
function Update-Config {
    param($key, $value)
    $content = Get-Content 'config.ini' -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    [System.IO.File]::WriteAllText("$PWD\config.ini", $content)
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

# Read config file
$config = @{}
if (Test-Path 'config.ini') {
    Get-Content 'config.ini' | ForEach-Object {
        if ($_ -match '^([^#].+?)=(.*)$') {
            $config[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

# Check if we need to run first-time setup
$requiredSettings = @(
    @{
        Key = "UNREALREZEN_DIR"
        Prompt = "Where is UnrealReZen installed?"
        Validator = "Directory"
        Example = "C:\UnrealReZen"
        Description = "The directory containing UnrealReZen.exe"
    },
    @{
        Key = "MOD_BASE_DIR"
        Prompt = "Where do you keep your mods?"
        Validator = "Directory"
        Example = "D:\FF7R-Mods"
        Description = "The directory where all your mod folders will be stored"
    },
    @{
        Key = "GAME_DIR"
        Prompt = "Where is FF7 Rebirth installed?"
        Validator = "Directory"
        Example = "C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY VII REBIRTH"
        Description = "Your FF7 Rebirth installation directory"
    },
    @{
        Key = "STEAM_EXE"
        Prompt = "Where is Steam installed?"
        Validator = "File"
        Example = "C:\Program Files (x86)\Steam\steam.exe"
        Description = "Path to your Steam executable"
    },
    @{
        Key = "STEAM_APPID"
        Prompt = "Steam App ID for FF7 Rebirth"
        Validator = "None"
        Example = "2909400"
        Description = "The Steam App ID for FF7 Rebirth (this should not need to change)"
    }
)

$needsSetup = $false
foreach ($setting in $requiredSettings) {
    if (-not $config.ContainsKey($setting.Key) -or [string]::IsNullOrWhiteSpace($config[$setting.Key])) {
        $needsSetup = $true
        break
    }
}

if ($needsSetup) {
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|      Tirien's Rebirth Mod Packager      |" -ForegroundColor Yellow
    Write-Host "|      Based on a script by Yoraiz0r      |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow
    
    Write-Host "Let's set up your configuration. You can change these settings later by editing config.ini`n" -ForegroundColor Cyan
    
    foreach ($setting in $requiredSettings) {
        Write-Host "+- Setting up: " -NoNewline -ForegroundColor Blue
        Write-Host $setting.Key -ForegroundColor White
        Write-Host "|  $($setting.Description)" -ForegroundColor Gray
        Write-Host "|  Example: " -NoNewline -ForegroundColor Blue
        Write-Host $setting.Example -ForegroundColor Gray
        Write-Host "+------------------" -ForegroundColor Blue
        
        $currentValue = if ($config.ContainsKey($setting.Key)) { $config[$setting.Key] } else { $null }
        
        $newValue = switch ($setting.Validator) {
            "Directory" { Get-ValidDirectory $setting.Prompt $currentValue }
            "File" { Get-ValidFile $setting.Prompt $currentValue }
            default {
                if ($currentValue) {
                    Write-Host "`n$($setting.Prompt)" -ForegroundColor Cyan
                    Write-Host "Current value: " -NoNewline
                    Write-Host $currentValue -ForegroundColor Green
                    $input = Read-Host "Press Enter to keep current value, or enter new value"
                    if ([string]::IsNullOrWhiteSpace($input)) { $currentValue } else { $input }
                } else {
                    Write-Host "`n$($setting.Prompt)" -ForegroundColor Cyan
                    Read-Host "Enter value"
                }
            }
        }
        
        $config[$setting.Key] = $newValue
        Update-Config $setting.Key $newValue
        Write-Host "(/) Setting saved!" -ForegroundColor Green
        Write-Host
    }
    
    Write-Host "+==========================================+" -ForegroundColor Green
    Write-Host "|          Configuration Complete!          |" -ForegroundColor Green
    Write-Host "+==========================================+" -ForegroundColor Green
    Write-Host "`nPress any key to continue..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
}

# Function to draw the menu
function Show-FolderMenu {
    param($folders, $selectedIndex, $lastUsedIndex)
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|      Tirien's Rebirth Mod Packager      |" -ForegroundColor Yellow
    Write-Host "|      Based on a script by Yoraiz0r      |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow

    Write-Host "Edit the config.ini to set up your base directories.`n" -ForegroundColor Cyan

    Write-Host "Your mod folder should be in:" -ForegroundColor Yellow
    Write-Host "$($config.MOD_BASE_DIR)" 
    Write-Host "...and contain a 'mod-content' folder which includes the full original filepath of all assets you are packaging.`n" -ForegroundColor Red

    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host "$($config.MOD_BASE_DIR)\"-NoNewline
    Write-Host "cloud-green-hair" -NoNewline -ForegroundColor Green
    Write-Host "\mod-content\End\Content\Character\Player\PC0000_00_Cloud_Standard\Texture\[PC0000_00_Hair_C.uasset, PC0000_00_Hair_C.ubulk]`n" 

    Write-Host "The script will convert dash-cased filenames into a PascalCased mod name. For example, assets in the mod folder 'cloud-green-hair' will be packaged as 'CloudGreenHair'.`n"

    Write-Host "Select a mod folder using arrow keys (UP/DOWN) and press Enter to confirm:" -ForegroundColor Yellow
    Write-Host "Press Escape to cancel and enter a name manually`n" -ForegroundColor Yellow
    
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

# Verify required settings
@('UNREALREZEN_DIR', 'MOD_BASE_DIR', 'GAME_DIR', 'STEAM_EXE', 'STEAM_APPID') | ForEach-Object {
    if (-not $config.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($config[$_])) {
        Write-Host "Error: $_ not set in config.ini"
        exit 1
    }
}

# Get current timestamp for directory naming
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

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
$gamePakDir = Join-Path $config.GAME_DIR "\End\Content\Paks"
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
    "--game-dir", $gamePakDir,
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
        Get-ChildItem -Path $gamePakDir -Directory | Where-Object { 
            $_.Name -like "$modName-*" 
        } | ForEach-Object {
            Write-Host "Removing: $($_.FullName)"
            Remove-Item $_.FullName -Recurse -Force
        }

        # Copy files to game directory
        $gameExportDir = Join-Path $gamePakDir "$modName-$timestamp"
        if (-not (Test-Path $gameExportDir)) {
            New-Item -ItemType Directory -Path $gameExportDir -Force | Out-Null
        }

        Write-Host "`nCopying files to game directory:"
        Write-Host $gameExportDir
        Copy-Item -Path $exportUtoc -Destination $gameExportDir -Force
        Copy-Item -Path $exportUcas -Destination $gameExportDir -Force
        Copy-Item -Path $exportPak -Destination $gameExportDir -Force
        Write-Host "Files copied successfully`n"

        # Launch game and exit
        Write-Host "Launching game..."
        Start-Process $config.STEAM_EXE -ArgumentList "-applaunch", $config.STEAM_APPID
        Start-Sleep -Seconds 3
        exit 0
    } 
} else {
    Write-Host "Error: UnrealReZen failed to export the mod files."
    exit 1
}
