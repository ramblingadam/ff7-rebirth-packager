$baseHairAssetPath = "End\Content\Character\Player"

$characterFiles = @{
  'Cloud' = @(
      'Cloud_Hair_C.uasset',
      'Cloud_Hair_N.uasset'
  )
  'Tifa' = @(
      'PC0002_00_Tifa_Standard/PC0002_00_Hair_C.uasset',
      'PC0002_05_Tifa_Soldier/PC0002_05_Hair_N.uasset',
      'PC0002_08_Tifa_CostaClothing/PC0002_08_Hair_C.uasset'
  )
  # 'Tifa' = @(
  #     'PC0002_00_Hair_C.uasset',
  #     'PC0002_05_Hair_C.uasset',
  #     'PC0002_08_Hair_C.uasset'
  # )
  'Barret' = @(
      'PC0001_00_Barret_Standard/PC0001_00_Hair_C.uasset'
  )
  'Aerith' = @(
      'Aerith_Hair_C.uasset',
      'Aerith_Hair_N.uasset'
  )
  'Red XIII' = @(
      'RedXIII_Fur_C.uasset',
      'RedXIII_Fur_N.uasset'
  )
  'Yuffie' = @(
      'Yuffie_Hair_C.uasset',
      'Yuffie_Hair_N.uasset'
  )
  'Cait Sith' = @(
      'CaitSith_Fur_C.uasset',
      'CaitSith_Fur_N.uasset'
  )
  'Vincent' = @(
      'Vincent_Hair_C.uasset',
      'Vincent_Hair_N.uasset'
  )
}

# Import functions from the packager script
. ..\packager\main.ps1

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
  Write-Host "Finding character files..."
  Write-Host "Mod path: $modPath"
  Write-Host "Target files: $targetFiles"
    param($modPath, $targetFiles)
    
    $foundFiles = @{}
    foreach ($file in $targetFiles) {
        Write-Host -NoNewline "Searching for $file... "
        $found = Get-ChildItem -Path $modPath -Recurse -Filter $file -ErrorAction SilentlyContinue
        if ($found) {
            Write-Host "Found!" -ForegroundColor Green
            $foundFiles[$file] = $found.FullName
        } else {
            Write-Host "Not found" -ForegroundColor Red
        }
    }
    return $foundFiles
}

# Main workflow
$character = Show-CharacterMenu
$targetFiles = $characterFiles[$character]

# Use the existing mod selection menu from main.ps1
$modPath = Show-ModMenu

# Find character files
$foundFiles = Find-CharacterFiles -modPath $modPath -targetFiles $targetFiles

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
    
    # Copy and rename texture file
    Copy-Item $texturePath $newTexturePath -Force
    
    # Call the texture injection script
    $pythonScript = Join-Path $PSScriptRoot "UE4-DDS-Tools\src\main.py"
    python $pythonScript --input $newTexturePath --output $targetFile
}

Write-Host "`nProcess completed!" -ForegroundColor Green