# Script 0: Instructions + Preflight (READ-ONLY)

Write-Host "=== SCRIPT 0: PRE-FLIGHT CHECK ==="
Write-Host ""
Write-Host "REQUIREMENTS BEFORE CONTINUING:"
Write-Host "1. PowerShell MUST be opened as Administrator"
Write-Host "2. OS MUST be Windows 11"
Write-Host "3. Virtualization MUST be enabled in BIOS (VT-x / SVM)"
Write-Host "4. Reboots are HARD STOPS in this workflow"
Write-Host ""

# ---- Execution Policy Check ----
$policy = Get-ExecutionPolicy -Scope LocalMachine

if ($policy -eq 'Restricted') {
    Write-Error "PowerShell execution policy is RESTRICTED."
    Write-Host ""
    Write-Host "Run the following command in an ELEVATED PowerShell, then re-run Script 0:"
    Write-Host ""
    Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine"
    Write-Host ""
    exit 1
}

# ---- Admin check ----
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "NOT RUNNING AS ADMINISTRATOR. STOP."
    exit 1
}

# ---- OS check ----
$os = Get-CimInstance Win32_OperatingSystem
if ($os.Caption -notmatch "Windows 11") {
    Write-Error "NOT WINDOWS 11. FOUND: $($os.Caption)"
    exit 1
}

# ---- Virtualization support check ----
$cpu = Get-CimInstance Win32_Processor
if (-not $cpu.VirtualizationFirmwareEnabled) {
    Write-Error "VIRTUALIZATION NOT ENABLED IN BIOS. STOP."
    exit 1
}

Write-Host ""
Write-Host "Preflight PASSED."
Write-Host "Proceed to Script 1: 1-bootstrap-wsl-docker.ps1"
exit 0
