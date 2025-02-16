# Import shared utilities
. ..\shared-utils.ps1

# Base path for hair assets
$baseHairAssetPath = "End/Content/Character/Player"

# Local source files (original hair textures to use as base)
$localCharacterFiles = @{
  'Cloud' = @(
    'cloud/PC0000_00_Hair_C.uasset',
    'cloud/PC0000_00_Hair_C.ubulk',
    'cloud/PC0000_06_Hair_C.uasset',
    'cloud/PC0000_06_Hair_C.ubulk'
  )
  'Tifa' = @(
    'tifa/PC0002_00_Hair_C.uasset',
    'tifa/PC0002_00_Hair_C.ubulk',
    'tifa/PC0002_05_Hair_C.uasset',
    'tifa/PC0002_05_Hair_C.ubulk',
    'tifa/PC0002_08_Hair_C.uasset',
    'tifa/PC0002_08_Hair_C.ubulk'
  )
  'Barret' = @(
    'barret/PC0001_00_Hair_C.uasset',
    'barret/PC0001_00_Hair_C.ubulk'
  )
  'Aerith' = @(
    'aerith/PC0003_00_Hair_C.uasset',
    'aerith/PC0003_00_Hair_C.ubulk',
    'aerith/PC0003_05_Hair_C.uasset',
    'aerith/PC0003_05_Hair_C.ubulk'
  )
  'Red XIII' = @(
    'red-xiii/PC0004_00_Hair_C.uasset',
    'red-xiii/PC0004_00_Hair_C.ubulk',
    'red-xiii/PC0004_02_Hair_C.uasset',
    'red-xiii/PC0004_02_Hair_C.ubulk'
  )
  'Yuffie' = @(
    'yuffie/PC0005_00_Hair_C.uasset',
    'yuffie/PC0005_00_Hair_C.ubulk'
  )
  'Cait Sith' = @(
    'cait-sith/PC0007_00_Hair_C.uasset',
    'cait-sith/PC0007_00_Hair_C.ubulk'
  )
}

# Target paths in mod directory
$characterFiles = @{
    'Cloud' = @(
        'PC0000_00_Cloud_Standard/Texture/PC0000_00_Hair_C.uasset',
        'PC0000_06_Cloud_Soldier/Texture/PC0000_06_Hair_C.uasset'
    )
    'Tifa' = @(
        'PC0002_00_Tifa_Standard/Texture/PC0002_00_Hair_C.uasset',
        'PC0002_05_Tifa_Soldier/Texture/PC0002_05_Hair_C.uasset',
        'PC0002_08_Tifa_CostaClothing/Texture/PC0002_08_Hair_C.uasset'
    )
    'Barret' = @(
        'PC0001_00_Barret_Standard/Texture/PC0001_00_Hair_C.uasset'
    )
    'Aerith' = @(
        'PC0003_00_Aerith_Standard/Texture/PC0003_00_Hair_C.uasset',
        'PC0003_05_Aerith_Soldier/Texture/PC0003_05_Hair_C.uasset'
    )
    'Red XIII' = @(
        'PC0004_00_RedXIII_Standard/Texture/PC0004_00_Hair_C.uasset',
        'PC0004_02_RedXIII_Loveless/Texture/PC0004_02_Hair_C.uasset'
    )
    'Yuffie' = @(
        'PC0005_00_Yuffie_Standard/Texture/PC0005_00_Hair_C.uasset'
    )
    'Cait Sith' = @(
        'PC0007_00_CaitSith_Standard/Texture/PC0007_00_Hair_C.uasset'
    )
    # 'Vincent' = @(
    #     'Vincent_Hair_C.uasset',
    #     'Vincent_Hair_C.uasset'
    # )
}

# Function to verify all required source files exist
function Test-SourceFiles {
    param($character)
    
    $sourceFiles = $localCharacterFiles[$character]
    $missingFiles = @()
    
    Write-Host "`nVerifying source files for $character..." -ForegroundColor Cyan
    foreach ($file in $sourceFiles) {
        $fullPath = Join-Path "original-hair" $file
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

# Function to verify files exist in mod content path
function Test-ModFiles {
    param(
        $character,
        $modContentPath
    )
    
    $missingFiles = @()
    $foundFiles = @()
    
    foreach ($targetPath in $characterFiles[$character]) {
        $fullPath = Join-Path $modContentPath (Join-Path $baseHairAssetPath $targetPath)
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
    foreach ($targetFile in $characterFiles[$character]) {
        $targetPath = Join-Path $modContentPath (Join-Path $baseHairAssetPath (Split-Path $targetFile -Parent))
        Write-Host "Creating directory: $targetPath"
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }
    
    return $modContentPath
}

# Function to inject textures
function Start-TextureInjection {
    param(
        $character,
        $modContentPath,
        $texturePath
    )
    
    Write-Host "`nInjecting textures..." -ForegroundColor Cyan
    
    # Get corresponding source and target files
    $sourceFiles = $localCharacterFiles[$character]
    $targetPaths = $characterFiles[$character]
    
    # Setup Python environment
    $toolsDir = Join-Path (Split-Path $PSScriptRoot -Parent) "tools\UE4-DDS-Tools-v0.6.1-Batch"
    $pythonExe = Join-Path $toolsDir "python\python.exe"
    $pythonScript = Join-Path $toolsDir "src\main.py"
    
    for ($i = 0; $i -lt $sourceFiles.Count; $i += 2) {  # Process in pairs (uasset + ubulk)
        $sourceUasset = Join-Path "original-hair" $sourceFiles[$i]
        $sourceUbulk = Join-Path "original-hair" $sourceFiles[$i+1]
        $targetPath = Join-Path $modContentPath (Join-Path $baseHairAssetPath $targetPaths[$i/2])
        $targetDir = Split-Path -Parent $targetPath
        
        Write-Host "`nProcessing $($sourceFiles[$i])"
        
        try {
            # Copy source files to target directory
            Write-Host "Copying source files..." -NoNewline
            Copy-Item $sourceUasset (Join-Path $targetDir (Split-Path $sourceUasset -Leaf)) -Force
            Copy-Item $sourceUbulk (Join-Path $targetDir (Split-Path $sourceUbulk -Leaf)) -Force
            Write-Host "Done!" -ForegroundColor Green
            
            # Copy and rename texture file
            $newTextureName = [System.IO.Path]::GetFileNameWithoutExtension($targetPath)
            $textureExt = [System.IO.Path]::GetExtension($texturePath)
            $newTexturePath = Join-Path $targetDir "$newTextureName$textureExt"
            
            Write-Host "Copying texture file..." -NoNewline
            Copy-Item $texturePath $newTexturePath -Force
            Write-Host "Done!" -ForegroundColor Green
            
            # Prepare for texture injection
            Write-Host "Running texture injection..." -NoNewline
            
            # Get the target uasset path
            $targetUasset = Join-Path $targetDir (Split-Path $sourceUasset -Leaf)
            
            # Change to the UE4-DDS-Tools directory
            Push-Location $toolsDir
            try {
                # Call Python directly with our custom arguments
                $pythonOutput = & $pythonExe -E $pythonScript $targetUasset $newTexturePath --save_folder="$targetDir" --skip_non_texture --image_filter=cubic 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Done!" -ForegroundColor Green
                    Write-Host "`nPython Script Output:" -ForegroundColor Yellow
                    $pythonOutput | ForEach-Object { Write-Host $_ }
                    
                    # Clean up the copied texture file
                    Write-Host "Cleaning up temporary texture file..." -NoNewline
                    if (Test-Path $newTexturePath) {
                        Remove-Item $newTexturePath -Force
                        Write-Host "Done!" -ForegroundColor Green
                    }
                } else {
                    Write-Host "Failed!" -ForegroundColor Red
                    Write-Host "`nPython Script Output:" -ForegroundColor Yellow
                    $pythonOutput | ForEach-Object { Write-Host $_ }
                    throw "Python script failed with exit code $LASTEXITCODE"
                }
            }
            finally {
                Pop-Location
            }
        }
        catch {
            Write-Host "`nError occurred while processing $($sourceFiles[$i]):" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            $continue = Read-Host "`nDo you want to continue with the remaining files? (Y/N)"
            if ($continue -ne 'Y') {
                exit
            }
        }
    }
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

# Function to show character selection menu
function Show-CharacterMenu {
    param(
        $selectedIndex,
        $lastUsedIndex
    )
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|         Select Character to Edit        |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow
    
    Write-Host "Select a character using arrow keys (UP/DOWN) and press Enter to confirm" -ForegroundColor Cyan
    Write-Host "(Or press 'C' to open configuration setup)`n" -ForegroundColor Yellow
    
    # Convert dictionary keys to array for consistent indexing
    $characters = @($characterFiles.Keys)
    
    for ($i = 0; $i -lt $characters.Count; $i++) {
        $prefix = if ($i -eq $selectedIndex) { "-> " } else { "   " }
        $suffix = if ($i -eq $lastUsedIndex) { " (last used)" } else { "" }
        if ($i -eq $selectedIndex) {
            Write-Host "$prefix$($characters[$i])$suffix" -ForegroundColor Green
        } else {
            Write-Host "$prefix$($characters[$i])$suffix"
        }
    }
}

# Function to get character selection
function Get-CharacterSelection {
    # Convert dictionary keys to array for consistent indexing
    $characters = @($characterFiles.Keys)
    
    # Find index of last used character
    $selectedIndex = 0
    $lastUsedIndex = -1
    if ($config.LAST_USED_CHARACTER) {
        $lastUsedIndex = [array]::IndexOf($characters, $config.LAST_USED_CHARACTER)
        if ($lastUsedIndex -ge 0) {
            $selectedIndex = $lastUsedIndex
        }
    }
    
    $maxIndex = $characters.Count - 1
    
    while ($true) {
        Show-CharacterMenu $selectedIndex $lastUsedIndex
        
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
                $selectedCharacter = $characters[$selectedIndex]
                # Update last used character in config
                Update-Config "LAST_USED_CHARACTER" $selectedCharacter
                return $selectedCharacter
            }
        }
    }
}

# Function to get texture path with previous path support
function Get-TexturePath {
    $lastUsedPath = $config['LAST_USED_TEXTURE_PATH']
    
    if ($lastUsedPath -and (Test-Path $lastUsedPath)) {
        Write-Host "`nPrevious texture: " -NoNewline
        Write-Host $lastUsedPath -ForegroundColor Green
        Write-Host "Press Enter to use previous texture, or enter a new path:"
    } else {
        Write-Host "`nEnter the path to your texture file (png, jpg, or bmp):"
    }
    
    do {
        $input = Read-Host
        
        # Use previous path if input is empty and previous path exists
        if ([string]::IsNullOrWhiteSpace($input) -and $lastUsedPath -and (Test-Path $lastUsedPath)) {
            $texturePath = $lastUsedPath
        } else {
            $texturePath = $input
        }
        
        # Validate the path
        if (-not (Test-Path $texturePath)) {
            Write-Host "Error: File does not exist!" -ForegroundColor Red
            continue
        }
        if (-not ($texturePath -match '\.(png|jpg|bmp)$')) {
            Write-Host "Error: File must be a png, jpg, or bmp!" -ForegroundColor Red
            continue
        }
        
        # Update config with new path
        if ($texturePath -ne $lastUsedPath) {
            Update-Config "LAST_USED_TEXTURE_PATH" $texturePath
        }
        
        return $texturePath
        
    } while ($true)
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
        -not $config.LAST_USED_TEXTURE_PATH) {
        Write-Host "`nError: Cannot perform quick update - missing last used settings." -ForegroundColor Red
        Write-Host "Please perform a regular update first to set all required values."
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $modFolder = $config.LAST_USED_MOD_FOLDER
    $character = $config.LAST_USED_CHARACTER
    $texturePath = $config.LAST_USED_TEXTURE_PATH
    
    # Verify mod folder exists
    $modContentPath = Join-Path $config['MOD_BASE_DIR'] "$modFolder\mod-content"
    if (-not (Test-Path $modContentPath)) {
        Write-Host "`nError: Mod folder not found:" -ForegroundColor Red
        Write-Host $modContentPath
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Verify texture exists
    if (-not (Test-Path $texturePath)) {
        Write-Host "`nError: Last used texture file not found:" -ForegroundColor Red
        Write-Host $texturePath
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Verify files exist in mod
    $fileCheck = Test-ModFiles $character $modContentPath
    if ($fileCheck.MissingFiles.Count -gt 0) {
        Write-Host "`nError: The following files are missing from the mod:" -ForegroundColor Red
        $fileCheck.MissingFiles | ForEach-Object { Write-Host $_ }
        Write-Host "`nThis mod doesn't appear to be a hair mod for $character."
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-Host "`nQuick updating mod using last settings:" -ForegroundColor Cyan
    Write-Host "Mod: " -NoNewline; Write-Host $modFolder -ForegroundColor Green
    Write-Host "Character: " -NoNewline; Write-Host $character -ForegroundColor Green
    Write-Host "Texture: " -NoNewline; Write-Host $texturePath -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # Start texture injection
    Start-TextureInjection $character $modContentPath $texturePath
    
    # Complete the operation and auto-launch
    Complete-ModOperation $modFolder $false -AutoLaunch
}

# Main script execution
while ($true) {
    # Read config file to get MOD_BASE_DIR
    $config = @{}
    if (Test-Path '..\config.ini') {
        Get-Content '..\config.ini' | ForEach-Object {
            if ($_ -match '^([^#].+?)=(.*)$') {
                $config[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }

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
        $character = Get-CharacterSelection
        if ($character -eq "CONFIG") {
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "By Tirien"
            continue
        }
        if (-not $character) { continue }
        
        # Verify source files
        $missingFiles = Test-SourceFiles $character
        if ($missingFiles.Count -gt 0) {
            Write-Host "`nError: The following source files are missing:" -ForegroundColor Red
            $missingFiles | ForEach-Object { Write-Host $_ }
            Write-Host "`nPlease extract these files from the game and place them in the original-hair directory."
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            continue
        }
        
        # Get texture path
        $texturePath = Get-TexturePath
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
        Start-TextureInjection $character $modContentPath $texturePath
        
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

        $character = Get-CharacterSelection
        if ($character -eq "CONFIG") {
            Start-ConfigSetup "FF7 Rebirth Hair Mod Maker" "A tool for creating hair mods"
            continue
        }
        if (-not $character) { continue }
        
        # Verify files exist in mod
        Write-Host "`nVerifying files in existing mod..."
        $fileCheck = Test-ModFiles $character $modContentPath
        
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
        $texturePath = Get-TexturePath
        if (-not $texturePath) { continue }
        
        # Ask about launching game after getting texture (if not set to always launch)
        $launchGame = $config.ALWAYS_LAUNCH_GAME -eq 'true'
        if (-not $launchGame) {
            Write-Host "`nWould you like to launch the game after packaging? (Y/N)" -ForegroundColor Cyan
            $launchKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $launchGame = $launchKey.Character -eq 'y' -or $launchKey.Character -eq 'Y'
        }
        
        Start-TextureInjection $character $modContentPath $texturePath
        
        # Complete the operation (will always package)
        Complete-ModOperation $modFolder $false -launchGame $launchGame -texturePath $texturePath
    }
}
