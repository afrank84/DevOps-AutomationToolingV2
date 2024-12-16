# Define the source and destination directories
$SourceDir = "E:\DCIM\Camera"    # Change this to the directory on your Android phone
$DestDir = "D:\00-SamsungBackup\Images\Camera" # Change this to your desired destination directory on the PC
$LogFile = "D:\00-SamsungBackup\transfer_log.txt" # Log file to track successes
$FailedLogFile = "D:\00-SamsungBackup\failed_files_log.txt" # Log file to track failures

# Create the destination directory if it doesn't exist
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}

# Process files in the source directory
Get-ChildItem -Path $SourceDir -File | ForEach-Object {
    $File = $_

    # Check if the file is already logged as processed
    if (Select-String -Path $LogFile, $FailedLogFile -SimpleMatch $File.FullName) {
        Write-Host "SKIPPED: $($File.Name) (Already processed)" -ForegroundColor Yellow
        return
    }

    try {
        # Attempt to copy the file
        Copy-Item -Path $File.FullName -Destination $DestDir -ErrorAction Stop
        # Log success
        Write-Host "SUCCESS: $($File.Name)" -ForegroundColor Green
        "$($File.FullName),Success" | Out-File -Append -FilePath $LogFile
    } catch {
        # Log failure
        Write-Host "FAIL: $($File.Name)" -ForegroundColor Red
        "$($File.FullName),Fail" | Out-File -Append -FilePath $FailedLogFile
    }
}
