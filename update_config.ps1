param($modFolder)

$lines = Get-Content 'config.ini' -Raw
$lines -split '\r?\n' | ForEach-Object {
    if ($_ -match '^LAST_USED_MOD_FOLDER=') {
        "LAST_USED_MOD_FOLDER=$modFolder"
    } else {
        $_
    }
} | Set-Content 'config.ini.tmp'
