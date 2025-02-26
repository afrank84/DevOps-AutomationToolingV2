# Get the computer name dynamically
$ComputerName = $env:COMPUTERNAME

# Get the current date/time stamp in the format YYYYMMDD_HHmmss
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Define the primary log file name on the C: drive
$LogFileC = "C:\file_log_${ComputerName}_$timestamp.csv"

# Define the path to scan (adjust if needed)
$ScanPath = "C:\"

# Recursively get all files and select properties:
#   - FullName: Complete file path (directory + file name)
#   - Name: File name only
#   - Extension: File extension
#   - Size_MB: File size in megabytes (rounded to 2 decimal places)
Get-ChildItem -Path $ScanPath -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object FullName, Name, Extension, @{Name="Size_MB"; Expression={[math]::Round($_.Length / 1MB, 2)}} |
    Export-Csv -Path $LogFileC -NoTypeInformation -Encoding UTF8

Write-Host "File scan complete. Log saved to $LogFileC"

# Attempt to detect if the script is running from a USB drive.
# This block will not cause the program to fail if any error occurs.
try {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        # Extract the drive letter from the script's path.
        $scriptDrive = Split-Path -Qualifier $scriptPath
        $scriptDrive = $scriptDrive.TrimEnd("\")
        # Query WMI for drive info; DriveType 2 indicates a removable drive (USB).
        $drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$scriptDrive'" -ErrorAction SilentlyContinue
        if ($drive -and $drive.DriveType -eq 2) {
            # Running from a USB drive: copy the log file there.
            $LogFileUSB = "${scriptDrive}\file_log_${ComputerName}_$timestamp.csv"
            try {
                Copy-Item -Path $LogFileC -Destination $LogFileUSB -Force
                Write-Host "Also copied log to USB: $LogFileUSB"
            }
            catch {
                Write-Host "Error copying log to USB: $_"
            }
        }
        else {
            Write-Host "Script is not running from a USB drive."
        }
    }
    else {
        Write-Host "Script path not available; assuming not running from USB."
    }
}
catch {
    Write-Host "Error detecting USB drive: $_"
}
