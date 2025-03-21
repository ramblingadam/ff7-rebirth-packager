$rootDir = Split-Path $PSScriptRoot -Parent

# Import shared utilities
. (Join-Path $rootDir "shared-utils.ps1")

# Import modules
. (Join-Path $rootDir "modules\texture-utils.ps1")
. (Join-Path $rootDir "modules\character-utils.ps1")
. (Join-Path $rootDir "modules\file-validation.ps1")
. (Join-Path $rootDir "modules\config-utils.ps1")

# Function to create mod directory structure
function New-ModDirectoryStructure {
    param(
        [Parameter(Mandatory)]
        [string]$modName,
        
        [Parameter(Mandatory)]
        [string]$character,
        
        [Parameter(Mandatory)]
        [string]$textureType
    )
    
    # Read config
    $config = Read-ConfigFile
    
    # Create mod content directory
    $modContentPath = Join-Path $config['MOD_BASE_DIR'] "$modName\mod-content"
    Write-Host "`nCreating mod directory structure..." -ForegroundColor Cyan
    
Write-Host $characterFiles
Write-Host $characterFiles[$character]
Write-Host $characterFiles[$character][$textureType]

    # Create directories for each target file
    foreach ($targetFile in $characterFiles[$character][$textureType]) {
        $targetDir = Split-Path $targetFile -Parent
        $targetPath = Join-Path $modContentPath $targetDir
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
        $texturePath = $null,
        [switch]$EarlyLoadOrder = $false
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
        # Start-ModPackaging -ModFolder $modFolder -Config $config -LaunchGame:$true -TexturePath $config.LAST_USED_TEXTURE_PATH
        Start-ModPackaging -ModFolder $modFolder -Config $config -LaunchGame:$true -TexturePath $texturePath
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
        "Update Existing Hair Mod",
        "Create Multi-Mod"
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
    $maxIndex = 2

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
    
    # Start texture injection process
    $success = Start-TextureInjectionProcess `
        -character $character `
        -modContentPath $modContentPath `
        -textureType $textureType `
        -texturePath $texturePath
    
    if (-not $success) {
        return
    }
    
    # Complete the operation and auto-launch
    Complete-ModOperation $modFolder $false -AutoLaunch
}


# Function to show multi-mod type menu
function Show-MultiModTypeMenu {
    param($selectedIndex = 0)
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|         Select Multi-Mod Type           |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow

    Write-Host "Select a type using arrow keys (UP/DOWN) and press Enter to confirm" -ForegroundColor Cyan
    Write-Host "Press 'C' to open configuration setup`n" -ForegroundColor Yellow
    
    $options = @(
        "Chocobo"
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

# Function to handle multi-mod type menu input
function Get-MultiModTypeSelection {
    $selectedIndex = 0
    $maxIndex = 0  # Only one option for now

    while ($true) {
        Show-MultiModTypeMenu $selectedIndex

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
                return $selectedIndex + 1
            }
        }
    }
}

# Function to handle chocobo multi-mod creation
function Start-ChocoboMultiMod {
    # Get texture type selection using Chocobo-standard as reference
    $textureType = Get-TextureTypeSelection "Chocobo-standard"
    if (-not $textureType) { return }
    
    # Get texture paths (will handle multi-texture automatically)
    $texturePath = Get-TexturePath "Chocobo-standard" $textureType
    if (-not $texturePath) { return }
    
    # Get all chocobo types
    $chocoboTypes = @(
        "Chocobo-standard",
        "Chocobo-mountain",
        "Chocobo-sand",
        "Chocobo-forest",
        "Chocobo-sky",
        "Chocobo-ocean"
    )
    
    Write-Host "`nCreating mods for all chocobo types..." -ForegroundColor Cyan
    
    $allSuccess = $true
    $createdMods = @()
    $successfulMods = @()
    
    foreach ($chocoboType in $chocoboTypes) {
        Write-Host "`nProcessing $chocoboType..." -ForegroundColor Yellow
        
        # Generate mod name using same pattern as single mod flow
        if ($texturePath -is [hashtable]) {
            # Multi-texture case
            $textureFileNames = $texturePath.Values | ForEach-Object {
                [System.IO.Path]::GetFileNameWithoutExtension($_)
            }
            $textureFileNameNoExt = $textureFileNames -join "-"
        } else {
            # Single texture case
            $textureFileName = Split-Path $texturePath -Leaf
            $textureFileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($textureFileName)
        }
        
        $newModFolder = "$chocoboType-$textureType-$textureFileNameNoExt".ToLower()
        $createdMods += $newModFolder
        
        # Create mod directory structure
        $modContentPath = New-ModDirectoryStructure $newModFolder $chocoboType $textureType
        
        # Start texture injection process
        $success = Start-TextureInjectionProcess `
            -character $chocoboType `
            -modContentPath $modContentPath `
            -textureType $textureType `
            -texturePath $texturePath
            
        if (-not $success) {
            $allSuccess = $false
            Write-Host "Failed to create mod for $chocoboType" -ForegroundColor Red
            continue
        }
        
        Write-Host "Successfully created mod structure for $chocoboType" -ForegroundColor Green
        
        # Get current timestamp for directory naming
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        # Convert dash-case to PascalCase for mod name
        $modName = ($newModFolder -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
        
        # Create timestamped export directory
        $exportDir = Join-Path $config.MOD_BASE_DIR "$newModFolder\${modName}-$timestamp"
        
        # Package the mod with BatchProcessing flag
        $success = Start-ModPackaging `
            -ModFolder $newModFolder `
            -Config $config `
            -TexturePath $texturePath `
            -BatchProcessing
            
        if (-not $success) {
            $allSuccess = $false
            Write-Host "Failed to package mod for $chocoboType" -ForegroundColor Red
            continue
        }
        
        Write-Host "Successfully packaged mod for $chocoboType" -ForegroundColor Green
        
        # Store successful mod details for potential installation
        $successfulMods += @{
            ModName = $modName
            Timestamp = $timestamp
            ExportUtoc = Join-Path $exportDir "z${modName}_P.utoc"
            ExportUcas = Join-Path $exportDir "z${modName}_P.ucas"
            ExportPak = Join-Path $exportDir "z${modName}_P.pak"
        }
    }
    
    if ($allSuccess) {
        Write-Host "`nAll chocobo mods created and packaged successfully!" -ForegroundColor Green
        
        # If auto-launch is enabled, install all mods and launch game
        if ($config.ALWAYS_LAUNCH_GAME -eq 'true') {
            Write-Host "`nAuto-launch is enabled. Installing all mods..." -ForegroundColor Yellow
            Install-MultiMods -ModDetails $successfulMods -Config $config
        }
    } else {
        Write-Host "`nSome mods failed to create or package. Please check the errors above." -ForegroundColor Red
    }
    
    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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

         # Get mod name
         if ($config.AUTO_NAME_MODS -eq "true") {
            # Handle multi-texture case
            if ($texturePath -is [hashtable]) {
                # Combine all texture filenames
                $textureFileNames = $texturePath.Values | ForEach-Object {
                    [System.IO.Path]::GetFileNameWithoutExtension($_)
                }
                $textureFileNameNoExt = $textureFileNames -join "-"
            } else {
                $textureFileName = Split-Path $texturePath -Leaf
                $textureFileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($textureFileName)
            }
            $newModFolder = "$character-$textureType-$textureFileNameNoExt".ToLower()
        } else {
            $newModFolder = Read-Host "`nEnter a name for your mod:"
            if ([string]::IsNullOrWhiteSpace($newModFolder)) { continue }
        }
        
        # Ask about launching game after getting texture (if not set to always launch)
        $launchGame = $config.ALWAYS_LAUNCH_GAME -eq 'true'
        if (-not $launchGame) {
            Write-Host "`nWould you like to launch the game after packaging? (Y/N)" -ForegroundColor Cyan
            $launchKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $launchGame = $launchKey.Character -eq 'y' -or $launchKey.Character -eq 'Y'
        }
        
        # Create mod directory structure
        $modContentPath = New-ModDirectoryStructure $newModFolder $character $textureType
        
        # Start texture injection process
        $success = Start-TextureInjectionProcess `
            -character $character `
            -modContentPath $modContentPath `
            -textureType $textureType `
            -texturePath $texturePath
        
        if (-not $success) {
            return
        }
        
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
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
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
        while (-not $texturePath) {
            $texturePath = Get-TexturePath $character $textureType
        Write-Host "Texture: " -NoNewline; Write-Host $texturePath -ForegroundColor Green
        if (-not $texturePath) { 
            Write-Host "`nError: No valid texture path found for $character ($textureType)." -ForegroundColor Red
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            continue 
        }
        }
        
        
        # Ask about launching game after getting texture (if not set to always launch)
        $launchGame = $config.ALWAYS_LAUNCH_GAME -eq 'true'
        if (-not $launchGame) {
            Write-Host "`nWould you like to launch the game after packaging? (Y/N)" -ForegroundColor Cyan
            $launchKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $launchGame = $launchKey.Character -eq 'y' -or $launchKey.Character -eq 'Y'
        }
        
        # Start texture injection process
        $success = Start-TextureInjectionProcess `
            -character $character `
            -modContentPath $modContentPath `
            -textureType $textureType `
            -texturePath $texturePath
        
        if (-not $success) {
            Write-Host "`nError: Failed to inject texture." -ForegroundColor Red
            Write-Host "Press any key to exit..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
        
        # Complete the operation (will always package)
        Complete-ModOperation $modFolder $false -launchGame $launchGame -texturePath $texturePath
    }

    # Create multi-mod
    if ($choice -eq 3) {
        $multiModType = Get-MultiModTypeSelection
        if ($multiModType -eq "CONFIG") {
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
            continue
        }
        
        # Currently only chocobo multi-mods are supported
        Start-ChocoboMultiMod
        continue
    }
}
