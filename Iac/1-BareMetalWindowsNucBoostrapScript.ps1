# ============================================
# Bare-metal Windows NUC Bootstrap Script
# ============================================
# Purpose:
#   - Prepare a clean, identical Windows host
#   - Enable WSL2
#   - Install Docker Desktop (WSL2 backend)
#   - Install Gitea Actions runner (not registered)
#
# Non-goals:
#   - No runner registration
#   - No repo assumptions
#   - No secrets
#   - No dev tooling (Python, Git, Qt)
#
# Safe to re-run
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "=== Windows NUC bootstrap starting ==="

# ------------------------------------------------
# 1. Enable required Windows features (minimal)
# ------------------------------------------------
Write-Host "Enabling required Windows features..."

dism.exe /online /enable-feature `
    /featurename:Microsoft-Windows-Subsystem-Linux `
    /all /norestart | Out-Null

dism.exe /online /enable-feature `
    /featurename:VirtualMachinePlatform `
    /all /norestart | Out-Null

# ------------------------------------------------
# 2. Configure WSL2
# ------------------------------------------------
Write-Host "Configuring WSL2..."

wsl --set-default-version 2 2>$null

# Do NOT install a distro
# Docker Desktop will manage its own WSL backend

# ------------------------------------------------
# 3. Install Docker Desktop (WSL2 backend)
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
# 4. Enforce Docker Desktop settings (WSL2 only)
# ------------------------------------------------
Write-Host "Configuring Docker Desktop settings..."

$dockerSettingsDir = "$env:APPDATA\Docker"
$dockerSettingsFile = "$dockerSettingsDir\settings.json"

if (-not (Test-Path $dockerSettingsDir)) {
    New-Item -ItemType Directory -Path $dockerSettingsDir -Force | Out-Null
}

if (Test-Path $dockerSettingsFile) {
    $settings = Get-Content $dockerSettingsFile | ConvertFrom-Json
} else {
    $settings = @{}
}

$settings.wslEngineEnabled = $true
$settings.useWindowsContainers = $false

$settings | ConvertTo-Json -Depth 20 |
    Set-Content $dockerSettingsFile -Encoding UTF8

# ------------------------------------------------
# 5. Install Gitea Actions runner (binary only)
# ------------------------------------------------
$runnerRoot = "C:\gitea-runner"
$runnerExe = "$runnerRoot\act_runner.exe"

if (-not (Test-Path $runnerExe)) {
    Write-Host "Installing Gitea Actions runner (not registering)..."

    New-Item -ItemType Directory -Path $runnerRoot -Force | Out-Null

    Invoke-WebRequest `
        -Uri "https://gitea.com/gitea/act_runner/releases/latest/download/act_runner_windows_amd64.exe" `
        -OutFile $runnerExe
} else {
    Write-Host "Gitea runner already installed. Skipping."
}

# ------------------------------------------------
# 6. Sanity checks (non-fatal)
# ------------------------------------------------
Write-Host "Sanity checks:"

Write-Host "- WSL status:"
try {
    wsl --status
} catch {
    Write-Host "  WSL status unavailable until reboot."
}

Write-Host "- Docker CLI:"
try {
    docker --version
} catch {
    Write-Host "  Docker CLI not available until Docker Desktop is started."
}

Write-Host "=== Bootstrap complete ==="
Write-Host "A reboot is REQUIRED before using Docker and WSL2."
