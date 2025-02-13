# Import shared utilities
. ..\shared-utils.ps1

# Base path for hair assets
$baseHairAssetPath = "End/Content/Character/Player"

# Character file mappings with correct paths
$characterFiles = @{
    'Cloud' = @(
        'PC0000_00_Cloud_Standard/Texture/PC0000_00_Cloud_Standard.uasset',
        'PC0000_06_Cloud_Soldier/Texture/PC0000_06_Cloud_Soldier.uasset'
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
    #     'Vincent_Hair_N.uasset'
    # )
}

# Read config file to get MOD_BASE_DIR
$config = @{}
if (Test-Path '..\config.ini') {
    Get-Content '..\config.ini' | ForEach-Object {
        if ($_ -match '^([^#].+?)=(.*)$') {
            $config[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

# Function to show character selection menu
function Show-CharacterMenu {
    Write-Host "`nSelect a character to modify:"
    $characters = $characterFiles.Keys | Sort-Object
    for ($i = 0; $i -lt $characters.Count; $i++) {
        Write-Host "$($i + 1). $($characters[$i])"
    }
    
    do {
        $selection = Read-Host "`nEnter the number of your selection"
        $index = [int]$selection - 1
    } while ($index -lt 0 -or $index -ge $characters.Count)
    
    return $characters[$index]
}

# Function to find files in mod directory
function Find-CharacterFiles {
    param($modContentPath, $targetFiles)
    
    Write-Host "Finding character files..."
    Write-Host "Mod path: $modContentPath"
    Write-Host "Target files: $targetFiles"

    $foundFiles = @{}
    foreach ($file in $targetFiles) {
        $fullPath = Join-Path $modContentPath (Join-Path $baseHairAssetPath $file)
        Write-Host -NoNewline "Searching for $file... "
        if (Test-Path $fullPath) {
            Write-Host "Found!" -ForegroundColor Green
            $foundFiles[$file] = $fullPath
        } else {
                Write-Host "Not found" -ForegroundColor Red
            }
        }
    return $foundFiles
}

# Main workflow
$character = Show-CharacterMenu
$targetFiles = $characterFiles[$character]

# Get mod folder path
$modName = Get-ModFolder $config
if ($modName -eq "CONFIG") {
    Write-Host "Configuration setup selected. Please run the packager to configure settings." -ForegroundColor Yellow
    exit
}
if (-not $modName) {
    exit
}
$modContentPath = Join-Path $config['MOD_BASE_DIR'] "$modName\mod-content"

# Find character files
$foundFiles = Find-CharacterFiles -modContentPath $modContentPath -targetFiles $targetFiles

# Check if all files were found
$allFound = $foundFiles.Count -eq $targetFiles.Count
if (-not $allFound) {
    Write-Host "`nWarning: Not all expected files were found!" -ForegroundColor Yellow
    $continue = Read-Host "Do you want to continue anyway? (Y/N)"
    if ($continue -ne 'Y') {
        exit
    }
} else {
    Write-Host "`nAll expected files found!" -ForegroundColor Green
}

# Get texture file path
do {
    $texturePath = Read-Host "`nEnter the path to your texture file (png, jpg, or bmp)"
} while (-not (Test-Path $texturePath) -or -not ($texturePath -match '\.(png|jpg|bmp)$'))

# Process each found file
foreach ($file in $foundFiles.GetEnumerator()) {
    $targetFile = $file.Value
    $newTextureName = [System.IO.Path]::GetFileNameWithoutExtension($targetFile)
    $textureExt = [System.IO.Path]::GetExtension($texturePath)
    $newTexturePath = Join-Path ([System.IO.Path]::GetDirectoryName($targetFile)) "$newTextureName$textureExt"
    
    Write-Host "`nProcessing file: $($file.Key)"
    Write-Host "Target file: $targetFile"
    Write-Host "New texture path: $newTexturePath"
    
    try {
        # Copy and rename texture file
        Write-Host "Copying texture file..." -NoNewline
        Copy-Item $texturePath $newTexturePath -Force
        Write-Host "Done!" -ForegroundColor Green
        
        # Call the texture injection script
        $toolsDir = Join-Path $PSScriptRoot "UE4-DDS-Tools-v0.6.1-Batch"
        $pythonExe = Join-Path $toolsDir "python\python.exe"
        $pythonScript = Join-Path $toolsDir "src\main.py"
        $filePathTxt = Join-Path $toolsDir "src\_file_path_.txt"
        
        Write-Host "Running texture injection..." -NoNewline
        
        # Write the target file path to _file_path_.txt
        Set-Content -Path $filePathTxt -Value $targetFile
        
        # Get the directory of the target file to use as save folder
        $saveFolder = Split-Path -Parent $targetFile
        
        # Change to the UE4-DDS-Tools directory
        Push-Location $toolsDir
        try {
            # Call Python directly with our custom arguments
            $pythonOutput = & $pythonExe -E $pythonScript $filePathTxt $newTexturePath --save_folder="$saveFolder" --skip_non_texture --image_filter=cubic 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Done!" -ForegroundColor Green
                Write-Host "`nPython Script Output:" -ForegroundColor Yellow
                $pythonOutput | ForEach-Object { Write-Host $_ }
                
                # Clean up the copied texture file
                Write-Host "Cleaning up temporary texture file..." -NoNewline
                if (Test-Path $newTexturePath) {
                    Remove-Item $newTexturePath -Force
                    Write-Host "Done!" -ForegroundColor Green
                } else {
                    Write-Host "File not found!" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Failed!" -ForegroundColor Red
                Write-Host "`nPython Script Output:" -ForegroundColor Yellow
                $pythonOutput | ForEach-Object { Write-Host $_ }
                throw "Python script failed with exit code $LASTEXITCODE"
            }
        }
        finally {
            # Always return to the original directory
            Pop-Location
        }
    }
    catch {
        Write-Host "`nError occurred while processing $($file.Key):" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $continue = Read-Host "`nDo you want to continue with the remaining files? (Y/N)"
        if ($continue -ne 'Y') {
            exit
        }
    }
}

Write-Host "`nProcess completed!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')