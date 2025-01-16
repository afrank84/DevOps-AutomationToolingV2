# Define the output directory for log collection
$OutputDirectory = "C:\ForensicLogs"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory
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

# Function to create shadow copy and copy locked files
function Copy-LockedFiles {
    param (
        [string]$Source,
        [string]$Destination
    )

    Write-Output "Creating shadow copy for: $Source"

    # Create a temporary script for diskshadow
    $DiskshadowScript = @"
SET CONTEXT PERSISTENT NOWRITERS
BEGIN BACKUP
ADD VOLUME C: ALIAS MyShadowCopy
CREATE
END BACKUP
LIST SHADOWS ALL
"@
    $ScriptPath = "$env:TEMP\diskshadow.txt"
    $DiskshadowOutput = "$env:TEMP\diskshadow_output.txt"
    $DiskshadowPath = "$env:TEMP\diskshadow_mount"

    Set-Content -Path $ScriptPath -Value $DiskshadowScript

    # Run diskshadow and capture the output
    diskshadow /s $ScriptPath > $DiskshadowOutput

    # Parse the shadow copy device name
    $ShadowDevice = Select-String -Path $DiskshadowOutput -Pattern "Shadow Copy Volume Name:" | ForEach-Object {
        $_ -match "Shadow Copy Volume Name:\s+(\\?\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy\d+)"
        $Matches[1]
    }

    if (-not $ShadowDevice) {
        Write-Output "Failed to create shadow copy."
        return
    }

    # Mount shadow copy
    $MountedPath = "$DiskshadowPath\ShadowCopy"
    if (-not (Test-Path -Path $MountedPath)) {
        New-Item -ItemType Directory -Path $MountedPath
    }
    subst Z: $ShadowDevice

    # Copy the file from the shadow copy
    $ShadowSource = "Z:" + ($Source -replace "^[A-Za-z]:", "")
    Copy-IfExists $ShadowSource $Destination

    # Clean up shadow copy
    subst Z: /d
    diskshadow /s $ScriptPath > $null
    Remove-Item -Path $ScriptPath -Force
    Remove-Item -Path $DiskshadowOutput -Force
}

# Collect Registry Hives using shadow copy
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

Write-Output "Collecting Browser Data..."
Copy-IfExists "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History" "$OutputDirectory\BrowserData\Chrome_History"

# Collect Shadow Copy Information
Write-Output "Listing Shadow Copies..."
vssadmin list shadows > "$OutputDirectory\ShadowCopies.txt"

Write-Output "Log collection completed. Logs saved to $OutputDirectory."
