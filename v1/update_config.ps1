param($modFolder)

# Read all lines and join with Windows line endings
$content = [string]::Join("`r`n", (Get-Content 'config.ini'))

# Replace the specific line
$content = $content -replace '(?m)^LAST_USED_MOD_FOLDER=.*$', "LAST_USED_MOD_FOLDER=$modFolder"

# Write back without adding extra newline
[System.IO.File]::WriteAllText('config.ini', $content)
