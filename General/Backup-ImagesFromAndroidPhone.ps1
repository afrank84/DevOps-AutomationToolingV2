# Define the source and destination directories
$SourceDir = "E:\DCIM\Camera"    # Change this to the directory on your Android phone
$DestDir = "D:\00-SamsungBackup\Images\Camera" # Change this to your desired destination directory on the PC
$LogFile = "D:\00-SamsungBackup\transfer_log.txt" # Log file to track progress
$FailedLogFile = "D:\00-SamsungBackup\failed_files_log.txt" # Log file for failed files

# Create the destination directory if it doesn't exist
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}

# Read already processed files into memory (both successes and failures)
$ProcessedFiles = @{}
if (Test-Path $LogFile) {
    $ProcessedFiles += Get-Content $LogFile | ForEach-Object { ($_ -split ',')[0] }
}
if (Test-Path $FailedLogFile) {
    $ProcessedFiles += Get-Content $FailedLogFile | ForEach-Object { ($_ -split ',')[0] }
}

# Initialize file enumerator
$FileEnumerator = Get-ChildItem -Path $SourceDir -File -Recurse | GetEnumerator()

# Process files one by one
while ($FileEnumerator.MoveNext()) {
    $File = $FileEnumerator.Current
    # Skip files that are already processed
    if ($File.FullName -in $ProcessedFiles) {
        continue
    }

    try {
        # Attempt to copy the file
        Copy-Item -Path $File.FullName -Destination $DestDir -ErrorAction Stop
        # Log success
        Write-Host "SUCCESS: $($File.Name)" -ForegroundColor Green
        "$($File.FullName),Success" | Add-Content -Path $LogFile
    } catch {
        # Log failure and move on
        Write-Host "FAIL: $($File.Name)" -ForegroundColor Red
        "$($File.FullName),Fail" | Add-Content -Path $FailedLogFile
    }
}
