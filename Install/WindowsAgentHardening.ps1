# Harden-Win11-Agent.ps1
# Purpose: Reduce cloud/consumer nags and disable OneDrive/Backup behaviors on Windows 11 "agent" machines.
# Run: PowerShell as Administrator

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "This script must be run as Administrator."
    }
}

function Set-RegDword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

function Disable-ConsumerFeatures {
    # Group Policy equivalent:
    # Computer Configuration > Administrative Templates > Windows Components > Cloud Content > Turn off Microsoft consumer experiences
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerFeatures" -Value 1

    # Common CloudContent toggles that reduce suggestions/tips
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1
}

function Disable-Spotlight-And-ContentDelivery-CurrentUser {
    # These are per-user knobs used by Windows Spotlight / suggestions
    $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

    # Disable various suggestion/spotlight channels
    Set-RegDword -Path $cdm -Name "RotatingLockScreenEnabled" -Value 0
    Set-RegDword -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Value 0
    Set-RegDword -Path $cdm -Name "SubscribedContent-338387Enabled" -Value 0  # Suggested apps
    Set-RegDword -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 0  # Tips
    Set-RegDword -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 0  # Suggestions
    Set-RegDword -Path $cdm -Name "SubscribedContent-338393Enabled" -Value 0  # Spotlight
    Set-RegDword -Path $cdm -Name "SubscribedContent-353694Enabled" -Value 0  # More suggestions (varies by build)
    Set-RegDword -Path $cdm -Name "SubscribedContent-353696Enabled" -Value 0

    # Disable "tailored experiences" style suggestions in user context
    Set-RegDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0
}

function Disable-WindowsWelcomeExperience-Policy {
    # Settings > System > Notifications > Additional settings:
    # "Show the Windows welcome experience after updates..."
    # Policy keys are not perfectly consistent across releases. These reduce common "welcome" surfaces.
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
}

function Disable-OneDrive-Policy {
    # Group Policy equivalent:
    # Computer Configuration > Administrative Templates > Windows Components > OneDrive > Prevent the usage of OneDrive for file storage
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1
}

function Remove-OneDrive-From-Startup {
    # Remove per-user startup run entry if present
    $run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $run) {
        $props = Get-ItemProperty -Path $run -ErrorAction SilentlyContinue
        if ($null -ne $props.OneDrive) {
            Remove-ItemProperty -Path $run -Name "OneDrive" -ErrorAction SilentlyContinue
        }
    }

    # Disable OneDrive scheduled tasks (names can vary)
    $taskNames = @(
        "OneDrive Per-Machine Standalone Update Task",
        "OneDrive Standalone Update Task",
        "OneDrive Reporting Task-S-1-5-21"
    )
    foreach ($t in $taskNames) {
        $task = Get-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue
        if ($null -ne $task) {
            Disable-ScheduledTask -TaskName $t | Out-Null
        }
    }
}

function Uninstall-OneDrive-Optional {
    # Optional removal. This is the most aggressive step.
    # If you rely on OneDrive for anything, do NOT run this.
    $systemRoot = $env:SystemRoot
    $paths = @(
        Join-Path $systemRoot "System32\OneDriveSetup.exe",
        Join-Path $systemRoot "SysWOW64\OneDriveSetup.exe"
    )

    foreach ($p in $paths) {
        if (Test-Path $p) {
            Start-Process -FilePath $p -ArgumentList "/uninstall" -Wait
        }
    }
}

function Remove-WindowsBackup-App {
    # Windows 11 "Windows Backup" app package (varies by build)
    $targets = @(
        "Microsoft.WindowsBackup"
    )

    foreach ($name in $targets) {
        # Remove for current user if installed
        $pkg = Get-AppxPackage -Name $name -ErrorAction SilentlyContinue
        if ($null -ne $pkg) {
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
        }

        # De-provision so it won't be installed for new users
        $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $name }
        if ($null -ne $prov) {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName | Out-Null
        }
    }
}

function Write-LocalAgentPolicyNote {
    # Creates a simple local text note to prevent "oops I signed in" mistakes
    $dir = "C:\AgentPolicy"
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    $note = @"
AGENT POLICY (LOCAL MACHINE)

- Do not sign into Microsoft services with a personal Microsoft Account.
- Do not enable OneDrive.
- Avoid Microsoft Store unless explicitly required for build/test.
- Treat this machine as a sealed agent.
"@
    Set-Content -Path (Join-Path $dir "AGENT_POLICY.txt") -Value $note -Encoding UTF8
}

Assert-Admin

Write-Host "Applying Windows 11 agent hardening..." -ForegroundColor Cyan

Disable-ConsumerFeatures
Disable-WindowsWelcomeExperience-Policy
Disable-Spotlight-And-ContentDelivery-CurrentUser

Disable-OneDrive-Policy
Remove-OneDrive-From-Startup

Remove-WindowsBackup-App
Write-LocalAgentPolicyNote

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Recommended: reboot to ensure policies and background components fully settle." -ForegroundColor Yellow
Write-Host ""
Write-Host "Optional (more aggressive): Uninstall-OneDrive-Optional" -ForegroundColor Yellow
Write-Host "If you want that, run: Uninstall-OneDrive-Optional" -ForegroundColor Yellow
