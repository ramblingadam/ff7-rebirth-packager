# Import shared utilities
. (Join-Path $PSScriptRoot "..\shared-utils.ps1")

# Import modules
. (Join-Path $PSScriptRoot "modules\texture-utils.ps1")
. (Join-Path $PSScriptRoot "modules\character-utils.ps1")


# Function to verify all required source files exist
function Test-SourceFiles {
    param(
        $character,
        $textureType = 'hair'  # Default to 'hair' for backward compatibility
    )
    
    $sourceFiles = $localCharacterFiles[$character][$textureType]
    $missingFiles = @()
    
    Write-Host "`nVerifying source files for $character ($textureType)..." -ForegroundColor Cyan
    foreach ($file in $sourceFiles) {
        $fullPath = Join-Path "original-assets" $file
        Write-Host -NoNewline "Checking $file... "
        if (Test-Path $fullPath) {
            Write-Host "Found!" -ForegroundColor Green
        } else {
            Write-Host "Missing!" -ForegroundColor Red
            $missingFiles += $file
        }
    }
    
    return $missingFiles
}

# Function to verify files exist in mod
function Test-ModFiles {
    param(
        $character,
        $modContentPath,
        $textureType = "hair"  # Default to hair for backward compatibility
    )
    
    $missingFiles = @()
    $foundFiles = @()
    
    foreach ($targetPath in $characterFiles[$character][$textureType]) {
        $fullPath = Join-Path $modContentPath $targetPath
        Write-Host "Checking for $fullPath..." -NoNewline
        
        if (Test-Path $fullPath) {
            Write-Host "Found!" -ForegroundColor Green
            $foundFiles += $fullPath
        } else {
            Write-Host "Not found!" -ForegroundColor Yellow
            $missingFiles += $fullPath
        }
    }
    
    return @{
        MissingFiles = $missingFiles
        FoundFiles = $foundFiles
    }
}

# Function to create mod directory structure
function New-ModDirectoryStructure {
    param($modName, $character)
    
    # Create mod content directory
    $modContentPath = Join-Path $config['MOD_BASE_DIR'] "$modName\mod-content"
    Write-Host "`nCreating mod directory structure..." -ForegroundColor Cyan
    
    # Create directories for each target file
    foreach ($targetFile in $characterFiles[$character].hair) {
        $targetPath = Join-Path $modContentPath (Join-Path  (Split-Path $targetFile -Parent))
        Write-Host "Creating directory: $targetPath"
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }
    
    return $modContentPath
}

# Function to ask user if they want to update an existing hair mod or make a new one
function Show-UpdateMenu {
    Write-Host "`nDo you want to update an existing hair mod or make a new one?"
    Write-Host "1. Make a new (unpacked) hair mod"
    Write-Host "2. Update existing (unpacked) hair mod"
    
    do {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        $index = -1
        if ([int]::TryParse($key.Character, [ref]$null)) {
            $index = [int]$key.Character - 1
        }
    } while ($index -lt 0 -or $index -ge 2)
    
    return $index
}


# Function to handle end of mod operation
function Complete-ModOperation {
    param(
        $modFolder,
        $isNew,
        [switch]$AutoLaunch = $false,
        $launchGame = $false,
        $texturePath = $null
    )
    
    # Update last used mod in config
    Update-Config "LAST_USED_MOD_FOLDER" $modFolder
    
    # Show completion message
    if ($isNew) {
        Write-Host "`nMod creation complete!" -ForegroundColor Green
    } else {
        Write-Host "`nMod update complete!" -ForegroundColor Green
    }
    
    if ($AutoLaunch) {
        Write-Host "`nQuick updating and launching..." -ForegroundColor Yellow
        Start-ModPackaging -ModFolder $modFolder -Config $config -LaunchGame:$true -TexturePath $config.LAST_USED_TEXTURE_PATH
        exit 0
    } else {
        Write-Host "`nStarting packaging process..." -ForegroundColor Yellow
        Start-ModPackaging -ModFolder $modFolder -Config $config -LaunchGame:$launchGame -TexturePath $texturePath
        exit 0
    }
    
    if (-not $AutoLaunch) {
        Write-Host "`nPress any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 0
}

# Function to show main menu
function Show-MainMenu {
    param($selectedIndex = 0)
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|        FF7 Rebirth Hair Mod Maker       |" -ForegroundColor Yellow
    Write-Host "|              By Tirien                  |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow

    Write-Host "Select an option using arrow keys (UP/DOWN) and press Enter to confirm" -ForegroundColor Cyan
    Write-Host "Press 'Q' for quick update using last settings" -ForegroundColor Yellow
    Write-Host "Press 'C' to open configuration setup`n" -ForegroundColor Yellow
    
    $options = @(
        "Create New Hair Mod",
        "Update Existing Hair Mod"
    )
    
    for ($i = 0; $i -lt $options.Count; $i++) {
        $prefix = if ($i -eq $selectedIndex) { "-> " } else { "   " }
        if ($i -eq $selectedIndex) {
            Write-Host "$prefix$($options[$i])" -ForegroundColor Green
        } else {
            Write-Host "$prefix$($options[$i])"
        }
    }
}

# Function to handle menu input
function Get-MenuSelection {
    $selectedIndex = 0
    $maxIndex = 1

    while ($true) {
        Show-MainMenu $selectedIndex

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
            81 { # 'Q' key
                return "QUICK"
            }
            13 { # Enter
                return $selectedIndex + 1
            }
        }
    }
}

# Function to perform quick update using last used settings
function Start-QuickUpdate {
    # Verify we have all required last used settings
    if (-not $config.LAST_USED_MOD_FOLDER -or 
        -not $config.LAST_USED_CHARACTER -or
        -not $config.LAST_USED_TEXTURE_TYPE) {
        Write-Host "`nError: Cannot perform quick update - missing last used settings." -ForegroundColor Red
        Write-Host "Please perform a regular update first to set all required values."
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $modFolder = $config.LAST_USED_MOD_FOLDER
    $character = $config.LAST_USED_CHARACTER
    $textureType = $config.LAST_USED_TEXTURE_TYPE
    
    # Verify the texture type is valid for this character
    $availableTypes = @($localCharacterFiles[$character].Keys | Sort-Object)
    if ($availableTypes -notcontains $textureType) {
        Write-Host "`nError: Invalid texture type '$textureType' for character $character." -ForegroundColor Red
        Write-Host "Please perform a regular update first to set the correct texture type."
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    # Verify mod folder exists
    $modContentPath = Join-Path $config['MOD_BASE_DIR'] "$modFolder\mod-content"
    if (-not (Test-Path $modContentPath)) {
        Write-Host "`nError: Mod folder not found:" -ForegroundColor Red
        Write-Host $modContentPath
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Get the texture path from character-specific config
    $configKey = ($character -replace ' ', '').ToUpper() + "_" + $textureType.ToUpper() + "_TEXTURE_PATH"
    $texturePath = $config[$configKey]
    
    if (-not $texturePath -or -not (Test-Path $texturePath)) {
        Write-Host "`nError: No valid texture path found for $character ($textureType):" -ForegroundColor Red
        Write-Host "Please perform a regular update first to set the texture path."
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-Host "`nQuick updating mod using last settings:" -ForegroundColor Cyan
    Write-Host "Mod: " -NoNewline; Write-Host $modFolder -ForegroundColor Green
    Write-Host "Character: " -NoNewline; Write-Host $character -ForegroundColor Green
    Write-Host "Texture Type: " -NoNewline; Write-Host $textureType -ForegroundColor Green
    Write-Host "Texture: " -NoNewline; Write-Host $texturePath -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # Start texture injection
    . (Join-Path $PSScriptRoot "modules\texture-utils.ps1")
    Start-TextureInjection $character $modContentPath $texturePath $textureType $localCharacterFiles $characterFiles 
    
    # Complete the operation and auto-launch
    Complete-ModOperation $modFolder $false -AutoLaunch
}

# Main script execution
while ($true) {
    # Read config file
    $config = Read-ConfigFile
    
    # Check if config values are set
    if (-not $config.MOD_BASE_DIR -or -not $config.GAME_DIR -or -not $config.STEAM_EXE) {
        Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
        continue
    }

    $choice = Get-MenuSelection
    
    if ($choice -eq "CONFIG") {
        Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
        continue
    }

    if ($choice -eq "QUICK") {
        Start-QuickUpdate
        continue
    }
    
    # Make new mod
    if ($choice -eq 1) {
        # Get mod name
        $newModFolder = Read-Host "`nEnter a name for your mod:"
        if ([string]::IsNullOrWhiteSpace($newModFolder)) { continue }
        
        # Select character
        $characterSelection = Get-CharacterSelection
        if ($characterSelection -eq "CONFIG") {
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
            continue
        }
        if (-not $characterSelection) { continue }
        
        $character = $characterSelection.Character
        $textureType = $characterSelection.TextureType
        
        # Verify source files
        $missingFiles = Test-SourceFiles $character $textureType
        if ($missingFiles.Count -gt 0) {
            Write-Host "`nError: The following source files are missing:" -ForegroundColor Red
            $missingFiles | ForEach-Object { Write-Host $_ }
            Write-Host "`nPlease extract these files from the game and place them in the original-assets directory."
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            continue
        }
        
        # Get texture path
        $texturePath = Get-TexturePath $character $textureType
        if (-not $texturePath) { continue }
        
        # Ask about launching game after getting texture (if not set to always launch)
        $launchGame = $config.ALWAYS_LAUNCH_GAME -eq 'true'
        if (-not $launchGame) {
            Write-Host "`nWould you like to launch the game after packaging? (Y/N)" -ForegroundColor Cyan
            $launchKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $launchGame = $launchKey.Character -eq 'y' -or $launchKey.Character -eq 'Y'
        }
        
        # Create mod directory structure
        $modContentPath = New-ModDirectoryStructure $newModFolder $character
        
        # Start texture injection
        . (Join-Path $PSScriptRoot "modules\texture-utils.ps1")
        Start-TextureInjection $character $modContentPath $texturePath $textureType $localCharacterFiles $characterFiles 
        
        # Complete the operation (will always package for new mods)
        Complete-ModOperation $newModFolder $true -launchGame $launchGame -texturePath $texturePath
    }

    # Update existing mod
    if ($choice -eq 2) {
        $modFolder = Get-ModFolder $config
        if ($modFolder -eq "CONFIG") {
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
            continue
        }
        if (-not $modFolder) { continue }

        $modContentPath = Join-Path $config['MOD_BASE_DIR'] "$modFolder\mod-content"

        $characterSelection = Get-CharacterSelection
        if ($characterSelection -eq "CONFIG") {
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "A tool for creating hair mods"
            continue
        }
        if (-not $characterSelection) { continue }
        
        $character = $characterSelection.Character
        $textureType = $characterSelection.TextureType
        
        # Verify files exist in mod
        Write-Host "`nVerifying files in existing mod..."
        $fileCheck = Test-ModFiles $character $modContentPath $textureType

        if ($fileCheck.MissingFiles.Count -gt 0) {
            Write-Host "`nWarning: Some files are missing in the mod:" -ForegroundColor Yellow
            $fileCheck.MissingFiles | ForEach-Object { Write-Host "- $_" }
            
            $proceed = Read-Host "`nWould you like to proceed anyway? (Y/N)"
            if ($proceed -ne 'Y') {
                Write-Host "`nExiting..." -ForegroundColor Red
                continue
            }
        } else {
            Write-Host "`nAll required files found in mod!" -ForegroundColor Green
        }
        
        # Get texture file path
        $texturePath = Get-TexturePath $character $textureType
        Write-Host "Texture: " -NoNewline; Write-Host $texturePath -ForegroundColor Green
        if (-not $texturePath) { 
            Write-Host "`nError: No valid texture path found for $character ($textureType)." -ForegroundColor Red
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            continue 
        }
        
        # Ask about launching game after getting texture (if not set to always launch)
        $launchGame = $config.ALWAYS_LAUNCH_GAME -eq 'true'
        if (-not $launchGame) {
            Write-Host "`nWould you like to launch the game after packaging? (Y/N)" -ForegroundColor Cyan
            $launchKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $launchGame = $launchKey.Character -eq 'y' -or $launchKey.Character -eq 'Y'
        }
        
        . (Join-Path $PSScriptRoot "modules\texture-utils.ps1")
        Start-TextureInjection $character $modContentPath $texturePath $textureType $localCharacterFiles $characterFiles 
        
        # Complete the operation (will always package)
        Complete-ModOperation $modFolder $false -launchGame $launchGame -texturePath $texturePath
    }
}
