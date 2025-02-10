param($modBaseDir)

Write-Host "Debug: Starting folder selection script"
Write-Host "Debug: Looking in directory: $modBaseDir"

# Get all folders in the mod directory
$folders = Get-ChildItem -Path $modBaseDir -Directory | Select-Object -ExpandProperty Name
Write-Host "Debug: Found $($folders.Count) folders"

if ($folders.Count -eq 0) {
    Write-Host "No mod folders found in $modBaseDir"
    Start-Sleep -Seconds 2
    exit 1
}

Write-Host "Debug: Folders found:"
$folders | ForEach-Object { Write-Host "  - $_" }
Start-Sleep -Seconds 1

$selectedIndex = 0
$maxIndex = $folders.Count - 1

# Function to draw the menu
function Draw-Menu {
    param($selected)
    Clear-Host
    Write-Host "Select a mod folder using arrow keys (UP/DOWN) and press Enter to confirm:"
    Write-Host "Press Escape to cancel and enter a name manually`n"
    
    for ($i = 0; $i -lt $folders.Count; $i++) {
        if ($i -eq $selected) {
            Write-Host "-> $($folders[$i])" -ForegroundColor Green
        } else {
            Write-Host "   $($folders[$i])"
        }
    }
}

# Main selection loop
while ($true) {
    Draw-Menu $selectedIndex

    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.VirtualKeyCode) {
        38 { # Up arrow
            $selectedIndex = [Math]::Max(0, $selectedIndex - 1)
        }
        40 { # Down arrow
            $selectedIndex = [Math]::Min($maxIndex, $selectedIndex + 1)
        }
        13 { # Enter
            $selectedFolder = $folders[$selectedIndex]
            $selectedFolder | Out-File -FilePath "selected_folder.tmp" -NoNewline
            exit 0
        }
        27 { # Escape
            Write-Host "Debug: User pressed Escape"
            exit 1
        }
    }
}
