$rootDir = Split-Path $PSScriptRoot -Parent

# Functions to verify necessary files and paths exists

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
  Write-Host "modcontentPath to check: $modContentPath" -ForegroundColor Cyan
  
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
