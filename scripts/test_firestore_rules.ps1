# Run Firestore rules unit tests against the local emulator.
# Usage: .\scripts\test_firestore_rules.ps1
#
# Windows PowerShell equivalent of scripts/test_firestore_rules.sh.
# Requires: PowerShell 5+, Node.js + npm, Firebase CLI on PATH.

$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$TestDir = Join-Path $env:TEMP 'fb-rules-test'

# 1. Ensure test deps are installed (one-time)
if (-not (Test-Path (Join-Path $TestDir 'node_modules/@firebase/rules-unit-testing'))) {
    Write-Host "Installing @firebase/rules-unit-testing in $TestDir..."
    New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
    Push-Location $TestDir
    try {
        npm init -y | Out-Null
        npm install --no-fund --no-audit @firebase/rules-unit-testing firebase | Out-Null
    } finally {
        Pop-Location
    }
}

# 2. Copy the latest rules + test script
Copy-Item -Force (Join-Path $ProjectRoot 'firestore.rules.test.js') (Join-Path $TestDir 'test.js')

# 3. Start emulator, run tests, kill emulator
Write-Host 'Starting Firestore emulator...'
Push-Location $TestDir
try {
    firebase emulators:exec --only firestore --project samaki-fresh 'node test.js'
} finally {
    Pop-Location
}