# Downloads the drift web runtime into web/ so the web build can open the
# database (without these, drift 404s at first DB use in the browser).
#
# Versions are pinned to pubspec.lock: drift 2.34.0, sqlite3 (Dart) 3.3.3.
# If a URL 404s after a dependency bump, grab the matching assets from:
#   https://github.com/simolus3/drift/releases
#   https://github.com/simolus3/sqlite3.dart/releases
#
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File tool\fetch_web_runtime.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$web = Join-Path $root 'web'

$files = @(
    @{
        Uri = 'https://github.com/simolus3/drift/releases/download/drift-2.34.0/drift_worker.js'
        Out = Join-Path $web 'drift_worker.js'
    },
    @{
        Uri = 'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.3.3/sqlite3.wasm'
        Out = Join-Path $web 'sqlite3.wasm'
    }
)

foreach ($f in $files) {
    Write-Host "Fetching $($f.Uri)"
    Invoke-WebRequest -Uri $f.Uri -OutFile $f.Out
    Write-Host "  -> $($f.Out)"
}

Write-Host 'Web runtime ready: web/drift_worker.js and web/sqlite3.wasm'
