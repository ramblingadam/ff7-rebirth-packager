$rootDir = Split-Path $PSScriptRoot -Parent

# Texture handling and injection utilities

# Import shared utilities
. (Join-Path $rootDir "shared-utils.ps1")

# Import config utilities
. (Join-Path $rootDir "modules/config-utils.ps1")

# Define texture type metadata
$textureTypeMetadata = @{
    "Red XIII" = @{
        "fur" = @{
            isMultiTexture = $true
            parts = @(
                @{ name = "body"; prompt = "BODY fur texture" },
                @{ name = "head"; prompt = "HEAD fur texture" }
            )
        }
    }
}

# Function to get texture path with previous path support
function Get-TexturePath {
    param(
        $character,
        $textureType
    )
    
    # Read config
    $config = Read-ConfigFile
    
    # Check if this is a multi-texture type
    $metadata = $textureTypeMetadata[$character]
    if ($metadata -and $metadata[$textureType] -and $metadata[$textureType].isMultiTexture) {
        $texturePaths = @{}
        
        # Get each texture part
        foreach ($part in $metadata[$textureType].parts) {
            Write-Host "`nEnter the path to the $($part.prompt) file (png, jpg, or bmp):"
            
            # Get and validate the texture path
            do {
                $input = Read-Host
                
                if (-not (Test-Path $input)) {
                    Write-Host "Error: File does not exist!" -ForegroundColor Red
                    continue
                }
                if (-not ($input -match '\.(png|jpg|bmp)$')) {
                    Write-Host "Error: File must be a png, jpg, or bmp!" -ForegroundColor Red
                    continue
                }
                
                $texturePaths[$part.name] = $input
                break
                
            } while ($true)
        }
        
        return $texturePaths
    }
    
    # Normal single texture handling
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


# Function to handle texture injection process
function Start-TextureInjectionProcess {
    param(
        [Parameter(Mandatory)]
        [string]$character,
        
        [Parameter(Mandatory)]
        [string]$modContentPath,
        
        [Parameter(Mandatory)]
        [string]$textureType,
        
        [Parameter(Mandatory)]
        $texturePath # Can be string or hashtable
    )
    
    # Import texture utils
    . (Join-Path $rootDir "modules\texture-utils.ps1")
    
    # Get source and target files
    $sourceFiles = $localCharacterFiles[$character][$textureType]
    $targetPaths = $characterFiles[$character][$textureType]
    
    # Check if this is a multi-texture case
    $metadata = $textureTypeMetadata[$character]
    if ($metadata -and $metadata[$textureType] -and $metadata[$textureType].isMultiTexture) {
        # Process each texture part
        $textureIndex = 0
        foreach ($part in $metadata[$textureType].parts) {
            Write-Host "`nProcessing $($part.prompt)..."
            
            $sourceUasset = Join-Path "original-assets" $sourceFiles[$textureIndex]
            $sourceUbulk = Join-Path "original-assets" $sourceFiles[$textureIndex + 1]
            $targetPath = Join-Path $modContentPath $targetPaths[$textureIndex/2]
            
            $success = Start-TextureInjection `
                -SourceUasset $sourceUasset `
                -SourceUbulk $sourceUbulk `
                -TargetPath $targetPath `
                -TexturePath $texturePath[$part.name]
            
            if (-not $success) {
                $continue = Read-Host "`nDo you want to continue with the remaining files? (Y/N)"
                if ($continue -ne 'Y') {
                    return $false
                }
            }
            
            $textureIndex += 2
        }
    }
    else {
        # Process single texture case
        for ($i = 0; $i -lt $sourceFiles.Count; $i += 2) {
            $sourceUasset = Join-Path "original-assets" $sourceFiles[$i]
            $sourceUbulk = Join-Path "original-assets" $sourceFiles[$i+1]
            $targetPath = Join-Path $modContentPath $targetPaths[$i/2]
            
            Write-Host "`nProcessing $($sourceFiles[$i])"
            
            $success = Start-TextureInjection `
                -SourceUasset $sourceUasset `
                -SourceUbulk $sourceUbulk `
                -TargetPath $targetPath `
                -TexturePath $texturePath
            
            if (-not $success) {
                $continue = Read-Host "`nDo you want to continue with the remaining files? (Y/N)"
                if ($continue -ne 'Y') {
                    return $false
                }
            }
        }
    }
    
    return $true
}