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

# Function to update config file
function Update-Config {
    param($key, $value)
    $content = Get-Content '..\config.ini' -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    [System.IO.File]::WriteAllText("$PWD\..\config.ini", $content)
}

# Read config file
$config = Read-ConfigFile

# Check if we need to run first-time setup
$requiredSettings = @(
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
    Start-ConfigSetup "Tirien's Rebirth Mod Packager" "Based on a script by Yoraiz0r"
}

# Main script execution
Clear-Host

# Check if config values are set
if (-not $config.MOD_BASE_DIR -or -not $config.GAME_DIR -or -not $config.STEAM_EXE) {
    Start-ConfigSetup "Tirien's Rebirth Mod Packager" "Based on a script by Yoraiz0r"
}

# Get mod folder selection
$modFolder = Get-ModFolder $config
if ($modFolder -eq "CONFIG") {
    Start-ConfigSetup "Tirien's Rebirth Mod Packager" "Based on a script by Yoraiz0r"
    continue
}
if (-not $modFolder) {
    exit
}

# Verify required settings
@('MOD_BASE_DIR', 'GAME_DIR', 'STEAM_EXE', 'STEAM_APPID') | ForEach-Object {
    if (-not $config.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($config[$_])) {
        Write-Host "Error: $_ not set in config.ini"
        exit 1
    }
}

# Update last used folder in config
Update-Config "LAST_USED_MOD_FOLDER" $modFolder

# Ask user if they want to install mod and launch game
Write-Host "`nWould you like to test the mod after packaging?" -ForegroundColor Cyan
Write-Host "Press Y to launch game after packaging, any other key to package only..." -ForegroundColor Gray

$key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$launchGame = $key.VirtualKeyCode -eq 89 # 'Y' key

# Start packaging process
Start-ModPackaging -ModFolder $modFolder -Config $config -LaunchGame:$launchGame
