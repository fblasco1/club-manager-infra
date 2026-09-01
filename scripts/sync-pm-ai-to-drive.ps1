# Sube sync-pm-ai.md a Google Drive usando rclone de Windows.
# Usar cuando WSL no tiene salida HTTPS (timeout a googleapis.com).
#
# PowerShell:
#   cd \\wsl.localhost\Ubuntu\home\francisco\ERSport\club_manager_infra
#   .\scripts\sync-pm-ai-to-drive.ps1
#
# Primera vez: copiar config OAuth de WSL a Windows:
#   .\scripts\sync-pm-ai-to-drive.ps1 -CopyConfigFromWsl

param(
    [switch]$CopyConfigFromWsl,
    [switch]$Dated,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SyncFile = Join-Path $RepoRoot "docs\club\sync-pm-ai.md"
$BitacoraFile = Join-Path $RepoRoot "docs\club\bitacora-de-desarrollo.md"
$BitacoraDriveName = if ($env:BITACORA_DRIVE_NAME) {
    $env:BITACORA_DRIVE_NAME
} elseif ($env:DEVLOG_DRIVE_NAME) {
    $env:DEVLOG_DRIVE_NAME
} else {
    "Bitacora de desarrollo.md"
}
$FolderId = if ($env:GOOGLE_DRIVE_FOLDER_ID) { $env:GOOGLE_DRIVE_FOLDER_ID } else { "1KAvGKTnyjkZ_RDjwyxe_c6E3teS0RWtQ" }
$Remote = if ($env:RCLONE_REMOTE) { $env:RCLONE_REMOTE } else { "gdrive-icdpe" }

$RcloneCandidates = @(
    "C:\Program Files (x86)\Rclone\rclone-v1.75.0-windows-amd64\rclone.exe",
    "C:\Program Files\Rclone\rclone.exe",
    "$env:LOCALAPPDATA\Programs\rclone\rclone.exe"
)
$Rclone = $RcloneCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Rclone) {
    $Rclone = (Get-Command rclone -ErrorAction SilentlyContinue).Source
}
if (-not $Rclone) {
    Write-Error "No se encontro rclone.exe. Instala desde https://rclone.org/downloads/"
}

$WinConfigDir = Join-Path $env:APPDATA "rclone"
$WinConfig = Join-Path $WinConfigDir "rclone.conf"
$WslConfig = "\\wsl.localhost\Ubuntu\home\francisco\.config\rclone\rclone.conf"

function Copy-RcloneConfigFromWsl {
    if (-not (Test-Path $WslConfig)) {
        Write-Error "No existe config WSL: $WslConfig - completa OAuth primero."
    }
    New-Item -ItemType Directory -Force -Path $WinConfigDir | Out-Null
    Copy-Item -Force $WslConfig $WinConfig
    Write-Host "OK: config copiada WSL -> $WinConfig" -ForegroundColor Green
}

if ($CopyConfigFromWsl) {
    Copy-RcloneConfigFromWsl
    exit 0
}

if (-not (Test-Path $SyncFile)) {
    Write-Error "No existe $SyncFile"
}

if (-not (Test-Path $WinConfig)) {
    Write-Host "No hay rclone.conf en Windows. Copiando desde WSL..." -ForegroundColor Yellow
    Copy-RcloneConfigFromWsl
}

$rcloneArgs = @(
    "copyto",
    $SyncFile,
    "${Remote}:sync-pm-ai.md",
    "--drive-root-folder-id=$FolderId",
    "--timeout", "2m",
    "--contimeout", "30s"
)
if ($DryRun) { $rcloneArgs += "--dry-run" }

Write-Host "==> rclone (Windows) -> ${Remote}:sync-pm-ai.md" -ForegroundColor Cyan
& $Rclone @rcloneArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (Test-Path $BitacoraFile) {
    $bitacoraArgs = @(
        "copyto",
        $BitacoraFile,
        "${Remote}:$BitacoraDriveName",
        "--drive-root-folder-id=$FolderId",
        "--timeout", "2m",
        "--contimeout", "30s"
    )
    if ($DryRun) { $bitacoraArgs += "--dry-run" }
    Write-Host "==> rclone (Windows) -> ${Remote}:$BitacoraDriveName" -ForegroundColor Cyan
    & $Rclone @bitacoraArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($Dated) {
    $datedName = "sync-pm-ai-$(Get-Date -Format 'yyyy-MM-dd').md"
    $rcloneArgsDated = @(
        "copyto",
        $SyncFile,
        "${Remote}:$datedName",
        "--drive-root-folder-id=$FolderId",
        "--timeout", "2m",
        "--contimeout", "30s"
    )
    if ($DryRun) { $rcloneArgsDated += "--dry-run" }
    Write-Host "==> copia fechada: ${Remote}:$datedName" -ForegroundColor Cyan
    & $Rclone @rcloneArgsDated
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "OK: sync + bitácora publicados en Drive." -ForegroundColor Green
