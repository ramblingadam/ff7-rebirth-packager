# Import shared utilities
. ..\shared-utils.ps1

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
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|      Tirien's Rebirth Mod Packager      |" -ForegroundColor Yellow
    Write-Host "|      Based on a script by Yoraiz0r      |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow
    
    Write-Host "Configuration Setup" -ForegroundColor Cyan
    
    # Get tool directory
    $config.UNREALREZEN_DIR = Get-ValidDirectory "Enter UnrealReZen directory path" $config.UNREALREZEN_DIR
    Update-Config "UNREALREZEN_DIR" $config.UNREALREZEN_DIR
    
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

# Function to update config file
function Update-Config {
    param($key, $value)
    $content = Get-Content '..\config.ini' -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    [System.IO.File]::WriteAllText("$PWD\..\config.ini", $content)
}

# Function to run configuration setup
function Start-ConfigSetup {
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|      Tirien's Rebirth Mod Packager      |" -ForegroundColor Yellow
    Write-Host "|      Based on a script by Yoraiz0r      |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow


    Write-Host "[!][!][!][!][!][!][!]  IMPORTANT  [!][!][!][[!]!][!][!][!]" -ForegroundColor Red
    Write-Host "[!]" -NoNewline -ForegroundColor Red
    Write-Host "    This script expects a specific file structure   " -NoNewLine
    Write-Host "[!]" -ForegroundColor Red
     Write-Host "[!]" -NoNewline -ForegroundColor Red
    Write-Host "    in your mod folder to function properly.        "  -NoNewLine
     Write-Host "[!]" -ForegroundColor Red
     Write-Host "[!]" -NoNewline -ForegroundColor Red
    Write-Host "    Please see README.md for instructions.          "  -NoNewLine
    Write-Host "[!]" -ForegroundColor Red
    Write-Host "[!][!][!][!][!][!][!][!][!]![!][!][!][!][!][[!]!][!][!][!]`n" -ForegroundColor Red
    
    Write-Host "Let's set up your file paths. You can change these settings by editing config.ini`n" -ForegroundColor Cyan
    
    foreach ($setting in $requiredSettings) {
        Write-Host "Setting up: " -NoNewline -ForegroundColor Blue
        Write-Host $setting.Key -ForegroundColor White
        Write-Host "$($setting.Description)" -ForegroundColor Gray
        Write-Host "Example: " -NoNewline -ForegroundColor Blue
        Write-Host $setting.Example -ForegroundColor Gray

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
        Write-Host "Setting saved!" -ForegroundColor Green
        Write-Host 
    }
    
    Write-Host "+==========================================+" -ForegroundColor Green
    Write-Host "|          Configuration Complete!         |" -ForegroundColor Green
    Write-Host "+==========================================+" -ForegroundColor Green
    Write-Host "`nPress any key to return to mod selection..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
}

# Read config file
$config = @{}
if (Test-Path '..\config.ini') {
    Get-Content '..\config.ini' | ForEach-Object {
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
        Description = "The directory where your amazing mods live"
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
        Description = "The Steam App ID for FF7 Rebirth (You shouldn't change this)"
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
    Start-ConfigSetup
}

# Main script

Clear-Host

# Get mod folder selection
$modFolder = Get-ModFolder $config
if ($modFolder -eq "CONFIG") {
    Start-ConfigSetup
    exit
}
if (-not $modFolder) {
    exit
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
$exportDir = Join-Path $config.MOD_BASE_DIR "$modFolder\${modName}-$timestamp"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# Set file paths
$gamePakDir = Join-Path $config.GAME_DIR "\End\Content\Paks"
$exportUtoc = Join-Path $exportDir "${modName}_P.utoc"
$exportUcas = Join-Path $exportDir "${modName}_P.ucas"
$exportPak = Join-Path $exportDir "${modName}_P.pak"

Write-Host "`nUsing Mod Name: " -NoNewline -ForegroundColor Yellow
Write-Host "$modName`n" -ForegroundColor Green
Start-Sleep -Seconds 1

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

    # Ask user if they want to install mod and launch game
    Write-Host "`nWould you like to test the mod now?" -ForegroundColor Cyan
    Write-Host "Press Y to launch game, any other key to exit..." -ForegroundColor Gray

    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if ($key.VirtualKeyCode -eq 89) { # 'Y' key
        # Clean up previous versions of this mod in game directory
        Write-Host "`nCleaning up previous versions in game directory..." -ForegroundColor Yellow
        Get-ChildItem -Path $gamePakDir -Directory | Where-Object { 
            $_.Name -like "$modName-*" 
        } | ForEach-Object {
            Write-Host "Removing: $($_.FullName)"
            Remove-Item $_.FullName -Recurse -Force
            Write-Host "Removed: $($_.FullName)" -ForegroundColor Green
        }
        Start-Sleep -Seconds 1

        # Copy files to game directory
        $gameExportDir = Join-Path $gamePakDir "$modName-$timestamp"
        if (-not (Test-Path $gameExportDir)) {
            New-Item -ItemType Directory -Path $gameExportDir -Force | Out-Null
        }

        Write-Host "`nCopying files to game directory:" -ForegroundColor Yellow
        Copy-Item -Path $exportUtoc -Destination $gameExportDir -Force
        Copy-Item -Path $exportUcas -Destination $gameExportDir -Force
        Copy-Item -Path $exportPak -Destination $gameExportDir -Force
        Write-Host "Files copied successfully`n" -ForegroundColor Green

        # Launch game and exit
        Write-Host "Launching game..." -ForegroundColor Yellow
        Start-Process $config.STEAM_EXE -ArgumentList "-applaunch", $config.STEAM_APPID
        Start-Sleep -Seconds 3
    }
    exit 0
} else {
    Write-Host "Error: UnrealReZen failed to export the mod files." -ForegroundColor Red
    exit 1
}
