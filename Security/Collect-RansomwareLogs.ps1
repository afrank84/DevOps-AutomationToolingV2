# Define the output directory for log collection
$OutputDirectory = "C:\ForensicLogs"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory
}

# Collect system information and save to a separate file
function Collect-SystemInfo {
    $SystemInfoFile = "$OutputDirectory\SystemInfo.txt"
    Write-Output "Collecting system information..."

    $Hostname = hostname
    $ComputerName = $env:COMPUTERNAME
    $WindowsVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    $SerialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
    $Accounts = Get-LocalUser | Select-Object Name, Enabled, LastLogon

    $SystemInfo = @"
    Hostname: $Hostname
    Computer Name: $ComputerName
    Windows Version: $WindowsVersion
    Serial Number: $SerialNumber
    
    User Accounts:
    @"
    $SystemInfo | Out-File -FilePath $SystemInfoFile -Encoding UTF8 -Append

    # Append user accounts information
    $Accounts | Format-Table | Out-String | Out-File -FilePath $SystemInfoFile -Encoding UTF8 -Append

    Write-Output "System information saved to $SystemInfoFile."
}

# Function to safely copy files and create subdirectories
function Copy-IfExists {
    param (
        [string]$Source,
        [string]$Destination
    )
    if (Test-Path -Path $Source) {
        $SubDir = Split-Path -Path $Destination -Parent
        if (-not (Test-Path -Path $SubDir)) {
            New-Item -ItemType Directory -Path $SubDir
        }
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Function to create a shadow copy and access locked files
function Copy-LockedFiles {
    param (
        [string]$Source,
        [string]$Destination
    )

    Write-Output "Creating shadow copy for: $Source"

    # Create a shadow copy using vssadmin
    $ShadowCopyOutput = vssadmin create shadow /for=C: 2>&1
    $ShadowDevice = $ShadowCopyOutput -match "Shadow Copy Volume Name:\s+(\\?\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy\d+)" | ForEach-Object {
        $Matches[1]
    }

    if (-not $ShadowDevice) {
        Write-Output "Failed to create shadow copy."
        return
    }

    # Mount the shadow copy
    $MountedPath = "Z:"
    subst $MountedPath $ShadowDevice

    # Copy the file from the shadow copy
    $ShadowSource = $MountedPath + ($Source -replace "^[A-Za-z]:", "")
    if (Test-Path -Path $ShadowSource) {
        Copy-Item -Path $ShadowSource -Destination $Destination -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "Failed to locate source file in shadow copy: $ShadowSource"
    }

    # Unmount the shadow copy
    subst $MountedPath /d
    Write-Output "Shadow copy unmounted."
}

# Collect system information
Collect-SystemInfo

# Collect locked files (e.g., registry hives and NTUSER.DAT)
Write-Output "Collecting Registry Hives..."
Copy-LockedFiles "C:\Windows\System32\Config\SAM" "$OutputDirectory\Registry\SAM"
Copy-LockedFiles "C:\Windows\System32\Config\SYSTEM" "$OutputDirectory\Registry\SYSTEM"
Copy-LockedFiles "C:\Windows\System32\Config\SECURITY" "$OutputDirectory\Registry\SECURITY"
Copy-LockedFiles "C:\Windows\System32\Config\SOFTWARE" "$OutputDirectory\Registry\SOFTWARE"
Copy-LockedFiles "$env:USERPROFILE\NTUSER.DAT" "$OutputDirectory\Registry\NTUSER.DAT"

# Collect other logs
Write-Output "Collecting Firewall Logs..."
Copy-IfExists "C:\Windows\System32\LogFiles\Firewall\pfirewall.log" "$OutputDirectory\Firewall\pfirewall.log"

Write-Output "Collecting Prefetch Files..."
Copy-IfExists "C:\Windows\Prefetch" "$OutputDirectory\Prefetch"

Write-Output "Collecting Recent Files..."
Copy-IfExists "$env:APPDATA\Microsoft\Windows\Recent" "$OutputDirectory\RecentFiles"

Write-Output "Collecting Task Scheduler Files..."
Copy-IfExists "C:\Windows\System32\Tasks" "$OutputDirectory\Tasks"

Write-Output "Log collection completed. Logs saved to $OutputDirectory."
