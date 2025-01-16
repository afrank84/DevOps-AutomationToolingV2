# Detect the currently plugged-in USB drive
$usbDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
    $_.Root -like "?:\" -and (Get-Volume -DriveLetter $_.Root[0]).DriveType -eq 'Removable'
}

if ($usbDrives.Count -eq 0) {
    Write-Output "No USB drive detected. Please ensure a USB device is plugged in."
    exit
}

# Assume the first detected USB drive (if multiple USB drives are plugged in)
$usbDrive = $usbDrives[0].Root
$outputFile = Join-Path $usbDrive "Results.txt"

# Clear the output file if it already exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Inform the user
Write-Output "Searching the entire system for files containing '0e0899' and saving results to the USB device ($usbDrive)..." | Tee-Object -FilePath $outputFile

# Get all drives on the system
$allDrives = Get-PSDrive -PSProvider FileSystem

# Loop through each drive and search
foreach ($drive in $allDrives) {
    try {
        Write-Output "Searching in $($drive.Root)..." | Tee-Object -FilePath $outputFile -Append
        Get-ChildItem -Path $drive.Root -Recurse -ErrorAction SilentlyContinue -File | Where-Object {
            $_.Name -like "*0e0899*"
        } | ForEach-Object {
            # Format the output as "Filename: FullPath"
            "Filename: $($_.Name), Location: $($_.FullName)"
        } | Tee-Object -FilePath $outputFile -Append
    } catch {
        Write-Output "Unable to access $($drive.Root). Skipping..." | Tee-Object -FilePath $outputFile -Append
    }
}

Write-Output "Search complete. Results saved to $outputFile"
