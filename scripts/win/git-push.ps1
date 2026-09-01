# git push desde Windows cuando WSL no tiene salida HTTPS a GitHub.
#
# PowerShell:
#   cd \\wsl.localhost\Ubuntu\home\francisco\ERSport\club_manager_infra
#   .\scripts\win\git-push.ps1
#   .\scripts\win\git-push.ps1 -Remote upstream -Branch mvp/secretaria-2026-06
#
# Desde WSL (wrapper):
#   ./scripts/win/git-push-via-windows.sh

param(
    [string]$Remote = "origin",
    [string]$Branch = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# safe.directory antes de cualquier git (repos en \\wsl.localhost\...)
$RepoRoot = (Get-Location).ProviderPath
$SafeDir = ($RepoRoot -replace '\\', '/')
$gitBase = @("-c", "safe.directory=$SafeDir")

$topLevel = (& git @gitBase rev-parse --show-toplevel 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Error "No es un repositorio git en: $RepoRoot`n$topLevel"
}

if (-not $Branch) {
    $Branch = (& git @gitBase branch --show-current).Trim()
    if (-not $Branch) {
        Write-Error "No se detectó rama actual. Pasá -Branch explícito."
    }
}

Write-Host "==> git push $Remote $Branch" -ForegroundColor Cyan
Write-Host "    repo: $RepoRoot" -ForegroundColor DarkGray

if ($DryRun) {
    & git @gitBase remote -v
    & git @gitBase status -sb
    & git @gitBase log -1 --oneline
    Write-Host "(dry-run: no se ejecutó push)" -ForegroundColor Yellow
    exit 0
}

& git @gitBase push -u $Remote $Branch
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK: push completado ($Remote $Branch)" -ForegroundColor Green
