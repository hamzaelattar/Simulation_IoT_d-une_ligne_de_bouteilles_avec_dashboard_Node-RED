$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtimeDir = Join-Path $projectRoot '.node-red-runtime'
$flowFile = Join-Path $projectRoot 'node-red\flows.json'

$env:DASHBOARD_FILE = Join-Path $projectRoot 'node-red\dashboard.html'
$env:SIMULATION_FILE = Join-Path $projectRoot 'SimulationTest.html'

if (-not (Get-Command node-red -ErrorAction SilentlyContinue)) {
    throw 'Node-RED est introuvable. Installez-le avec : npm install -g node-red'
}

New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null

Write-Host ''
Write-Host 'Dashboard :  http://127.0.0.1:1880/dashboard' -ForegroundColor Cyan
Write-Host 'Simulation : http://127.0.0.1:1880/simulation' -ForegroundColor Cyan
Write-Host 'Editeur :    http://127.0.0.1:1880' -ForegroundColor DarkCyan
Write-Host 'Arrêt : Ctrl+C' -ForegroundColor Yellow
Write-Host ''

& node-red --userDir $runtimeDir --port 1880 --no-telemetry $flowFile

