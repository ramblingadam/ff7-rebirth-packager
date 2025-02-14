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

# Function to validate directory exists
function Test-DirectoryValid {
    param($path)
    return (Test-Path $path -PathType Container)
}

# Function to validate file exists
function Test-FileValid {
    param($path)
    return (Test-Path $path -PathType Leaf)
}

# Function to get a valid directory from user
function Get-ValidDirectory {
    param($prompt, $currentValue)
    
    while ($true) {
        Write-Host "`n$prompt" -ForegroundColor Cyan
        if ($currentValue) {
            Write-Host "Current value: " -NoNewline
            Write-Host $currentValue -ForegroundColor Green
            $input = Read-Host "Press Enter to keep current value, or enter new path"
            if ([string]::IsNullOrWhiteSpace($input)) {
                return $currentValue
            }
        } else {
            $input = Read-Host "Enter path"
        }
        
        if (Test-DirectoryValid $input) {
            return $input
        }
        Write-Host " Directory not found. Please enter a valid path." -ForegroundColor Red
    }
}

# Function to get a valid file from user
function Get-ValidFile {
    param($prompt, $currentValue)
    
    while ($true) {
        Write-Host "`n$prompt" -ForegroundColor Cyan
        if ($currentValue) {
            Write-Host "Current value: " -NoNewline
            Write-Host $currentValue -ForegroundColor Green
            $input = Read-Host "Press Enter to keep current value, or enter new path"
            if ([string]::IsNullOrWhiteSpace($input)) {
                return $currentValue
            }
        } else {
            $input = Read-Host "Enter path"
        }
        
        if (Test-FileValid $input) {
            return $input
        }
        Write-Host " File not found. Please enter a valid path." -ForegroundColor Red
    }
}

# Function to start configuration setup
function Start-ConfigSetup {
    param(
        $title = "Configuration Setup",
        $subtitle = ""
    )
    Clear-Host
    Write-Host "+=========================================+" -ForegroundColor Yellow
    Write-Host "|$(' ' * [math]::Floor((41 - $title.Length) / 2))$title$(' ' * [math]::Ceiling((41 - $title.Length) / 2))|" -ForegroundColor Yellow
    if ($subtitle) {
        Write-Host "|$(' ' * [math]::Floor((41 - $subtitle.Length) / 2))$subtitle$(' ' * [math]::Ceiling((41 - $subtitle.Length) / 2))|" -ForegroundColor Yellow
    }
    Write-Host "+=========================================+`n" -ForegroundColor Yellow
    
    Write-Host "Configuration Setup" -ForegroundColor Cyan
    
    # Get mod base directory
    $config.MOD_BASE_DIR = Get-ValidDirectory "Enter mod base directory path" $config.MOD_BASE_DIR
    Update-Config "MOD_BASE_DIR" $config.MOD_BASE_DIR
    
    # Get game directory
    $config.GAME_DIR = Get-ValidDirectory "Enter game directory path" $config.GAME_DIR
    Update-Config "GAME_DIR" $config.GAME_DIR
    
    # Get Steam executable
    $config.STEAM_EXE = Get-ValidFile "Enter Steam executable path" $config.STEAM_EXE
    Update-Config "STEAM_EXE" $config.STEAM_EXE
}
