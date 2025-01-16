# Define the output directory for log collection
$OutputDirectory = "C:\ForensicLogs"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory
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

# Collect locked files (e.g., registry hives and NTUSER.DAT)
Write-Output "Collecting Registry Hives..."
Copy-LockedFiles "C:\Windows\System32\Config\SAM" "$OutputDirectory\Registry\SAM"
Copy-LockedFiles "C:\Windows\System32\Config\SYSTEM" "$OutputDirectory\Registry\SYSTEM"
Copy-LockedFiles "C:\Windows\System32\Config\SECURITY" "$OutputDirectory\Registry\SECURITY"
Copy-LockedFiles "C:\Windows\System32\Config\SOFTWARE" "$OutputDirectory\Registry\SOFTWARE"
Copy-LockedFiles "$env:USERPROFILE\NTUSER.DAT" "$OutputDirectory\Registry\NTUSER.DAT"

# Collect other logs
Write-Output "Collecting Firewall Logs..."
Copy-Item -Path "C:\Windows\System32\LogFiles\Firewall\pfirewall.log" -Destination "$OutputDirectory\Firewall" -Force -ErrorAction SilentlyContinue

Write-Output "Collecting Prefetch Files..."
Copy-Item -Path "C:\Windows\Prefetch" -Destination "$OutputDirectory\Prefetch" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Collecting Recent Files..."
Copy-Item -Path "$env:APPDATA\Microsoft\Windows\Recent" -Destination "$OutputDirectory\RecentFiles" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Collecting Task Scheduler Files..."
Copy-Item -Path "C:\Windows\System32\Tasks" -Destination "$OutputDirectory\Tasks" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Log collection completed. Logs saved to $OutputDirectory."
