# Texture handling and injection utilities

# Import shared utilities
. (Join-Path $PSScriptRoot "..\..\shared-utils.ps1")

# Function to get texture path with previous path support
function Get-TexturePath {
    param(
        $character,
        $textureType
    )
    
    # Read config
    $config = Read-ConfigFile
    
    # Build config key for this character and texture type
    $configKey = ($character -replace ' ', '').ToUpper() + "_" + $textureType.ToUpper() + "_TEXTURE_PATH"
    $lastUsedPath = $config[$configKey]
      
    if ($lastUsedPath -and (Test-Path $lastUsedPath)) {
        Write-Host "`nPrevious texture for $character ($textureType): " -NoNewline
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
            Update-Config $configKey $texturePath
        }
        
        return $texturePath
        
    } while ($true)
}
