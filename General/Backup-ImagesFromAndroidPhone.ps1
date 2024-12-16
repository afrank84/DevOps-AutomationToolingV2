# Define the source and destination directories
$SourceDir = "E:\DCIM\Camera"    # Change this to the directory on your Android phone
$DestDir = "D:\00-SamsungBackup\Images\Camera" # Change this to your desired destination directory on the PC
$LogFile = "D:\00-SamsungBackup\transfer_log.txt" # Log file to track progress

# Create the destination directory if it doesn't exist
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir | Out-Null
}

# Load log file into memory if it exists
$ProcessedFiles = @{}
if (Test-Path $LogFile) {
    $ProcessedFiles = Get-Content $LogFile | ForEach-Object {
        $line = $_ -split ','
        @{ Name = $line[0]; Status = $line[1] }
    } | Group-Object Name | ForEach-Object { $_.Group[0] }
}

# Get a list of files from the source directory
$Files = Get-ChildItem -Path $SourceDir -File -Recurse | Where-Object { $_.FullName -notin $ProcessedFiles.Name }

# Process each file
foreach ($File in $Files) {
    try {
        # Move the file
        Move-Item -Path $File.FullName -Destination $DestDir
        # Log success
        Write-Host "SUCCESS: $($File.Name)" -ForegroundColor Green
        "$($File.FullName),Success" | Add-Content -Path $LogFile
    } catch {
        # Log failure
        Write-Host "FAIL: $($File.Name)" -ForegroundColor Red
        "$($File.FullName),Fail" | Add-Content -Path $LogFile
    }
}
