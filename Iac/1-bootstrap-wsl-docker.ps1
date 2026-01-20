# Script 1: Bootstrap WSL2 + Docker (MUTATING)
# MUST be run as Administrator
# HARD STOP AFTER THIS SCRIPT -> REBOOT REQUIRED

$ErrorActionPreference = "Stop"

Write-Host "=== SCRIPT 1: BOOTSTRAP WSL2 + DOCKER ==="

# ---- Enable Windows features ----
dism.exe /online /enable-feature `
    /featurename:Microsoft-Windows-Subsystem-Linux `
    /all /norestart | Out-Null

dism.exe /online /enable-feature `
    /featurename:VirtualMachinePlatform `
    /all /norestart | Out-Null

# ---- Configure WSL ----
wsl --set-default-version 2 2>$null

# ---- Install Docker Desktop ----
$dockerExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$installer = "$env:TEMP\DockerDesktopInstaller.exe"

if (-not (Test-Path $dockerExe)) {
    Invoke-WebRequest `
        -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" `
        -OutFile $installer

    Start-Process `
        -FilePath $installer `
        -ArgumentList "install --quiet --accept-license" `
        -Wait
}

Write-Host ""
Write-Host "SCRIPT 1 COMPLETE."
Write-Host "REBOOT NOW."
Write-Host "AFTER REBOOT, CONTINUE WITH SCRIPT 2."
exit 0
