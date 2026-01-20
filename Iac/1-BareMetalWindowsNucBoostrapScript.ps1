# ============================================
# Bare-metal Windows NUC Bootstrap Script
# ============================================
# Purpose:
#   - Enable WSL2
#   - Install Docker Desktop (WSL2 backend)
#
# Notes:
#   - Requires reboot to complete
#   - No runner setup
#   - No dev tooling
#   - Intended to be run early in a chained script flow
#
# Safe to re-run
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "=== Windows NUC bootstrap starting (WSL2 + Docker only) ==="

# ------------------------------------------------
# 1. Enable required Windows features
# ------------------------------------------------
Write-Host "Enabling WSL2 Windows features..."

dism.exe /online /enable-feature `
    /featurename:Microsoft-Windows-Subsystem-Linux `
    /all /norestart | Out-Null

dism.exe /online /enable-feature `
    /featurename:VirtualMachinePlatform `
    /all /norestart | Out-Null

# ------------------------------------------------
# 2. Set WSL default to version 2
# ------------------------------------------------
Write-Host "Setting WSL default version to 2..."

wsl --set-default-version 2 2>$null

# ------------------------------------------------
# 3. Install Docker Desktop
# ------------------------------------------------
$dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"

if (-not (Test-Path $dockerExe)) {
    Write-Host "Docker Desktop not found. Downloading installer..."

    Invoke-WebRequest `
        -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" `
        -OutFile $dockerInstaller

    Write-Host "Installing Docker Desktop..."
    Start-Process `
        -FilePath $dockerInstaller `
        -ArgumentList "install --quiet --accept-license" `
        -Wait
} else {
    Write-Host "Docker Desktop already installed. Skipping."
}

# ------------------------------------------------
# 4. Stop here – reboot required
# ------------------------------------------------
Write-Host "=== Bootstrap step complete ==="
Write-Host "REBOOT REQUIRED before continuing with further scripts."
