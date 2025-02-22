$rootDir = Split-Path $PSScriptRoot -Parent

# Configuration handling utilities


# Function to read config file
function Read-ConfigFile {
  $configPath = Join-Path $rootDir "config.ini"
  $config = @{}
  if (Test-Path $configPath) {
      Get-Content $configPath | ForEach-Object {
          if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
              $config[$matches[1].Trim()] = $matches[2].Trim()
          }
      }
  }
  return $config
}

# Function to update config file
function Update-Config {
  param($key, $value)
  $configPath = Join-Path $rootDir "config.ini"
  $content = Get-Content $configPath -Raw
  $content = $content -replace "(?m)^$key=.*$", "$key=$value"
  [System.IO.File]::WriteAllText($configPath, $content)
}