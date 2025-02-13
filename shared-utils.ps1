# Function to draw the menu
function Show-FolderMenu {
    param($folders, $selectedIndex, $lastUsedIndex, $title = "Mod Folder Selection")
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|            $title            |" -ForegroundColor Yellow
    Write-Host "+=========================================+`n" -ForegroundColor Yellow

    Write-Host "Select a mod folder using arrow keys (UP/DOWN) and press Enter to confirm" -ForegroundColor Cyan
    Write-Host "(Or press 'C' to open configuration setup)`n" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $folders.Count; $i++) {
        $prefix = if ($i -eq $selectedIndex) { "-> " } else { "   " }
        $suffix = if ($i -eq $lastUsedIndex) { " (last used)" } else { "" }
        if ($i -eq $selectedIndex) {
            Write-Host "$prefix$($folders[$i])$suffix" -ForegroundColor Green
        } else {
            Write-Host "$prefix$($folders[$i])$suffix"
        }
    }
}

# Function to get mod folder selection
function Get-ModFolder {
    param($config)
    $folders = Get-ChildItem -Path $config.MOD_BASE_DIR -Directory | Select-Object -ExpandProperty Name
    
    if ($folders.Count -gt 0) {
        # Find index of last used folder
        $selectedIndex = 0
        $lastUsedIndex = -1
        if ($config.LAST_USED_MOD_FOLDER) {
            $lastUsedIndex = [array]::IndexOf($folders, $config.LAST_USED_MOD_FOLDER)
            if ($lastUsedIndex -ge 0) {
                $selectedIndex = $lastUsedIndex
            }
        }
        
        $maxIndex = $folders.Count - 1

        while ($true) {
            Show-FolderMenu $folders $selectedIndex $lastUsedIndex

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
                    $selectedFolder = $folders[$selectedIndex]
                    # Update last used folder in config
                    Update-Config "LAST_USED_MOD_FOLDER" $selectedFolder
                    return $selectedFolder
                }
            }
        }
    } else {
        Write-Host "No mod folders found in $($config.MOD_BASE_DIR)" -ForegroundColor Red
        return $null
    }
}

# Function to update config file
function Update-Config {
    param($key, $value)
    $configPath = Join-Path $PSScriptRoot "config.ini"
    $content = Get-Content $configPath -Raw
    $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    [System.IO.File]::WriteAllText($configPath, $content)
}
