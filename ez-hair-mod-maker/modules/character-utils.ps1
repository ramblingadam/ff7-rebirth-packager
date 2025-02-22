# Character selection and validation utilities
. (Join-Path $PSScriptRoot "..\..\shared-utils.ps1")
. (Join-Path $PSScriptRoot "config-utils.ps1")
$basePlayerCharacterAssetPath = "End/Content/Character/Player"
# Local source files (original hair textures to use as base)
$localCharacterFiles = @{
    'Cloud' = @{
        'hair' = @(
            'cloud/PC0000_00_Hair_C.uasset',
            'cloud/PC0000_00_Hair_C.ubulk',
            'cloud/PC0000_06_Hair_C.uasset',
            'cloud/PC0000_06_Hair_C.ubulk'
        )
    }
    'Tifa' = @{
        'hair' = @(
            'tifa/PC0002_00_Hair_C.uasset',
            'tifa/PC0002_00_Hair_C.ubulk',
            'tifa/PC0002_05_Hair_C.uasset',
            'tifa/PC0002_05_Hair_C.ubulk',
            'tifa/PC0002_08_Hair_C.uasset',
            'tifa/PC0002_08_Hair_C.ubulk'
        )
    }
    'Barret' = @{
        'hair' = @(
            'barret/PC0001_00_Hair_C.uasset',
            'barret/PC0001_00_Hair_C.ubulk'
        )
    }
    'Aerith' = @{
        'hair' = @(
            'aerith/PC0003_00_Hair_C.uasset',
            'aerith/PC0003_00_Hair_C.ubulk',
            'aerith/PC0003_05_Hair_C.uasset',
            'aerith/PC0003_05_Hair_C.ubulk'
        )
    }
    'Red XIII' = @{
        'hair' = @(
            'red-xiii/PC0004_00_Hair_C.uasset',
            'red-xiii/PC0004_00_Hair_C.ubulk',
            'red-xiii/PC0004_02_Hair_C.uasset',
            'red-xiii/PC0004_02_Hair_C.ubulk'
        )
        'fur' = @(
            'red-xiii/PC0004_00_Body_C.uasset',
            'red-xiii/PC0004_00_Body_C.ubulk',
            'red-xiii/PC0004_00_Head_C.uasset',
            'red-xiii/PC0004_00_Head_C.ubulk'
        )
    }
    'Yuffie' = @{
        'hair' = @(
            'yuffie/PC0005_00_Hair_C.uasset',
            'yuffie/PC0005_00_Hair_C.ubulk'
        )
    }
    'Cait Sith' = @{
        'hair' = @(
            'cait-sith/PC0007_00_Hair_C.uasset',
            'cait-sith/PC0007_00_Hair_C.ubulk'
        )
    }
}

# Target paths in mod directory
$characterFiles = @{
    'Cloud' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0000_00_Cloud_Standard/Texture/PC0000_00_Hair_C.uasset",
            "$basePlayerCharacterAssetPath/PC0000_06_Cloud_Soldier/Texture/PC0000_06_Hair_C.uasset"
        )
    }
    'Tifa' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0002_00_Tifa_Standard/Texture/PC0002_00_Hair_C.uasset",
            "$basePlayerCharacterAssetPath/PC0002_05_Tifa_Soldier/Texture/PC0002_05_Hair_C.uasset",
            "$basePlayerCharacterAssetPath/PC0002_08_Tifa_CostaClothing/Texture/PC0002_08_Hair_C.uasset"
        )
    }
    'Barret' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0001_00_Barret_Standard/Texture/PC0001_00_Hair_C.uasset"
        )
    }
    'Aerith' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0003_00_Aerith_Standard/Texture/PC0003_00_Hair_C.uasset",
            "$basePlayerCharacterAssetPath/PC0003_05_Aerith_Soldier/Texture/PC0003_05_Hair_C.uasset"
        )
    }
    'Red XIII' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0004_00_RedXIII_Standard/Texture/PC0004_00_Hair_C.uasset",
            "$basePlayerCharacterAssetPath/PC0004_02_RedXIII_Loveless/Texture/PC0004_02_Hair_C.uasset"
        )
        'fur' = @(
            "$basePlayerCharacterAssetPath/PC0004_00_RedXIII_Standard/Texture/PC0004_00_Body_C.uasset",
            "$basePlayerCharacterAssetPath/PC0004_00_RedXIII_Standard/Texture/PC0004_00_Fur_C.uasset"
        )
    }
    'Yuffie' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0005_00_Yuffie_Standard/Texture/PC0005_00_Hair_C.uasset"
        )
    }
    'Cait Sith' = @{
        'hair' = @(
            "$basePlayerCharacterAssetPath/PC0007_00_CaitSith_Standard/Texture/PC0007_00_Hair_C.uasset"
        )
    }
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
    $characters = @($localCharacterFiles.Keys)
    
    for ($i = 0; $i -lt $characters.Count; $i++) {
        $char = $characters[$i]
        $textureTypes = "(" + ($localCharacterFiles[$char].Keys -join ", ") + ")"
        $prefix = if ($i -eq $selectedIndex) { "-> " } else { "   " }
        $suffix = if ($i -eq $lastUsedIndex) { " (last used)" } else { "" }
        if ($i -eq $selectedIndex) {
            Write-Host "$prefix$char $textureTypes$suffix" -ForegroundColor Green
        } else {
            Write-Host "$prefix$char $textureTypes$suffix"
        }
    }
}

# Function to get character selection
function Get-CharacterSelection {
    # Convert dictionary keys to array for consistent indexing
    $characters = @($localCharacterFiles.Keys)
    
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
                return @{
                    Character = $selectedCharacter
                    TextureType = Get-TextureTypeSelection $selectedCharacter
                }
            }
        }
    }
}

# Function to show texture type selection menu
function Show-TextureTypeMenu {
    param(
        $character,
        $selectedIndex = 0
    )
    
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|        Select Texture Type to Edit      |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow
    
    Write-Host "Select a texture type for $character using arrow keys (UP/DOWN) and press Enter to confirm`n" -ForegroundColor Cyan
    
    # Get available texture types
    $textureTypes = @($localCharacterFiles[$character].Keys | Sort-Object)
    
    for ($i = 0; $i -lt $textureTypes.Count; $i++) {
        $type = $textureTypes[$i]
        $prefix = if ($i -eq $selectedIndex) { "-> " } else { "   " }
        if ($i -eq $selectedIndex) {
            Write-Host "$prefix$type" -ForegroundColor Green
        } else {
            Write-Host "$prefix$type"
        }
    }
}

# Function to get texture type selection
function Get-TextureTypeSelection {
    param($character)
    
    # Get available texture types
    $textureTypes = @($localCharacterFiles[$character].Keys | Sort-Object)
    
    # If only one type available, return it automatically
    if ($textureTypes.Count -eq 1) {
        $type = $textureTypes[0]
        Write-Host "`nMaking a $type mod!" -ForegroundColor Cyan
        Update-Config "LAST_USED_TEXTURE_TYPE" $type
        return $type
    }
    
    $selectedIndex = 0
    $maxIndex = $textureTypes.Count - 1
    
    # Try to select the last used type if available
    if ($config.LAST_USED_TEXTURE_TYPE) {
        $lastUsedIndex = [array]::IndexOf($textureTypes, $config.LAST_USED_TEXTURE_TYPE)
        if ($lastUsedIndex -ge 0) {
            $selectedIndex = $lastUsedIndex
        }
    }
    
    while ($true) {
        Show-TextureTypeMenu $character $selectedIndex
        
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                if ($selectedIndex -gt 0) { $selectedIndex-- }
            }
            40 { # Down arrow
                if ($selectedIndex -lt $maxIndex) { $selectedIndex++ }
            }
            13 { # Enter
                $selectedType = $textureTypes[$selectedIndex]
                Write-Host "`nMaking a $selectedType mod!" -ForegroundColor Cyan
                Update-Config "LAST_USED_TEXTURE_TYPE" $selectedType
                return $selectedType
            }
        }
    }
}
