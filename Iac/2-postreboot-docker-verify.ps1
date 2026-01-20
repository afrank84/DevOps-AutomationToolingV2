# Script 2: Post-Reboot Verification
# Assumes reboot has already occurred

Write-Host "=== SCRIPT 2: POST-REBOOT VERIFICATION ==="

# ---- WSL ----
try {
    wsl --status
} catch {
    Write-Error "WSL NOT AVAILABLE."
    exit 1
}

# ---- Docker ----
try {
    docker version
} catch {
    Write-Error "DOCKER NOT READY. START DOCKER DESKTOP."
    exit 1
}

Write-Host ""
Write-Host "Docker and WSL verified."
Write-Host "Proceed with Docker-based workflows (Gitea runner, etc)."
exit 0
