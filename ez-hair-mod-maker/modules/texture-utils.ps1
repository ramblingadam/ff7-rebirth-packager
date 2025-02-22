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

# Function to inject textures
function Start-TextureInjection {
    param(
        $character,
        $modContentPath,
        $texturePath,
        $textureType,
        $localCharacterFiles,
        $characterFiles,
        $baseHairAssetPath
    )
    
    Write-Host "`nInjecting textures..." -ForegroundColor Cyan
    
    # Get corresponding source and target files
    $sourceFiles = $localCharacterFiles[$character][$textureType]
    $targetPaths = $characterFiles[$character][$textureType]
    
    # Setup Python environment
    $toolsDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "tools\UE4-DDS-Tools-v0.6.1-Batch"
    $pythonExe = Join-Path $toolsDir "python\python.exe"
    $pythonScript = Join-Path $toolsDir "src\main.py"
    
    for ($i = 0; $i -lt $sourceFiles.Count; $i += 2) {  # Process in pairs (uasset + ubulk)
        $sourceUasset = Join-Path "original-assets" $sourceFiles[$i]
        $sourceUbulk = Join-Path "original-assets" $sourceFiles[$i+1]
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
                Start-Sleep -Seconds 1

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
