# PowerShell companion for migrate_fisherman_to_street_seller.sh.
# Run on Windows if you don't have Git Bash.
#
# Usage:
#   .\scripts\migrate_fisherman_to_street_seller.ps1 -DryRun
#   .\scripts\migrate_fisherman_to_street_seller.ps1 -ProjectId "samaki-fresh"
#   .\scripts\migrate_fisherman_to_street_seller.ps1 -Emulator

param(
  [switch]$DryRun,
  [string]$ProjectId = "",
  [switch]$Emulator
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ScriptDir = Join-Path $env:TEMP ("fb-migrate-" + [DateTimeOffset]::Now.ToUnixTimeSeconds())
$LogFile = Join-Path $ProjectRoot "firestore-migration.log"

$Env:DRY_RUN = if ($DryRun) { "true" } else { "false" }
$Env:USE_EMULATOR = if ($Emulator) { "true" } else { "false" }
$Env:PROJECT_ID = if ($ProjectId -ne "") { $ProjectId } else { "" }
$Env:SCRIPT_DIR = $ScriptDir
$Env:PROJECT_ROOT = $ProjectRoot
$Env:LOG_FILE = $LogFile

if (-not (Test-Path "$ScriptDir/node_modules/firebase-admin")) {
  Write-Host "Installing firebase-admin in $ScriptDir..."
  New-Item -ItemType Directory -Force -Path $ScriptDir | Out-Null
  Push-Location $ScriptDir
  npm init -y | Out-Null
  npm install --no-fund --no-audit firebase-admin | Out-Null
  Pop-Location
}

Write-Host "Migration settings:"
Write-Host "  Project:    $Env:PROJECT_ID"
Write-Host "  Emulator:   $Env:USE_EMULATOR"
Write-Host "  Dry-run:    $Env:DRY_RUN"
Write-Host "  Log file:   $LogFile"
Write-Host ""

node "$ProjectRoot/scripts/migrate_fisherman_to_street_seller.js"
