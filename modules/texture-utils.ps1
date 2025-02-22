$rootDir = Split-Path $PSScriptRoot -Parent

# Texture handling and injection utilities

# Import shared utilities
. (Join-Path $rootDir "shared-utils.ps1")

# Import config utilities
. (Join-Path $rootDir "modules/config-utils.ps1")

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

# Function to inject a single texture
function Start-TextureInjection {
    param(
        [Parameter(Mandatory)]
        [string]$SourceUasset,
        
        [Parameter(Mandatory)]
        [string]$SourceUbulk,
        
        [Parameter(Mandatory)]
        [string]$TargetPath,
        
        [Parameter(Mandatory)]
        [string]$TexturePath
    )
    
    Write-Host "`nInjecting texture..." -ForegroundColor Cyan
    
    # Setup Python environment
    $toolsDir = Join-Path $rootDir "tools\UE4-DDS-Tools-v0.6.1-Batch"
    $pythonExe = Join-Path $toolsDir "python\python.exe"
    $pythonScript = Join-Path $toolsDir "src\main.py"
    
    # Get target directory
    $targetDir = Split-Path -Parent $TargetPath
    
    try {
        # Create target directory if it doesn't exist
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copy source files
        Write-Host "Copying source files..." -NoNewline
        Copy-Item $SourceUasset (Join-Path $targetDir (Split-Path $SourceUasset -Leaf)) -Force
        Copy-Item $SourceUbulk (Join-Path $targetDir (Split-Path $SourceUbulk -Leaf)) -Force
        Write-Host "Done!" -ForegroundColor Green
        
        # Copy and rename texture file
        $newTextureName = [System.IO.Path]::GetFileNameWithoutExtension($TargetPath)
        $textureExt = [System.IO.Path]::GetExtension($TexturePath)
        $newTexturePath = Join-Path $targetDir "$newTextureName$textureExt"
        
        Write-Host "Copying texture file..." -NoNewline
        Copy-Item $TexturePath $newTexturePath -Force
        Write-Host "Done!" -ForegroundColor Green
        
        # Run texture injection
        Write-Host "Running texture injection..." -NoNewline
        $targetUasset = Join-Path $targetDir (Split-Path $SourceUasset -Leaf)
        
        Push-Location $toolsDir
        try {
            $pythonOutput = & $pythonExe -E $pythonScript $targetUasset $newTexturePath --save_folder="$targetDir" --skip_non_texture --image_filter=cubic 2>&1
            Start-Sleep -Seconds 1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Done!" -ForegroundColor Green
                Write-Host "`nPython Script Output:" -ForegroundColor Yellow
                $pythonOutput | ForEach-Object { Write-Host $_ }
                
                # Clean up temporary file
                if (Test-Path $newTexturePath) {
                    Remove-Item $newTexturePath -Force
                }
                
                return $true
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
        Write-Host "`nError occurred while processing texture:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
}
