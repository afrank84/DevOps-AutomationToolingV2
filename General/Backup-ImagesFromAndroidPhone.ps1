# Define source, destination, and log files
$SourceDir = "E:\DCIM\Camera"
$DestDir = "D:\00-SamsungBackup\Images\Camera"
$LogFile = "D:\00-SamsungBackup\transfer_log.txt"
$FailedLogFile = "D:\00-SamsungBackup\failed_files_log.txt"

# Preload processed files
$ProcessedFiles = @{}
if (Test-Path $LogFile) {
    $ProcessedFiles += Get-Content $LogFile | ForEach-Object { ($_ -split ',')[0] }
}
if (Test-Path $FailedLogFile) {
    $ProcessedFiles += Get-Content $FailedLogFile | ForEach-Object { ($_ -split ',')[0] }
}

# Function to safely copy a file with timeout simulation
function Safe-Copy {
    param (
        [string]$SourceFile,
        [string]$DestinationDir
    )
    $StartTime = [DateTime]::Now
    try {
        Copy-Item -Path $SourceFile -Destination $DestinationDir -ErrorAction Stop
        return $true
    } catch {
        # Log the error message (optional for debugging)
        Write-Host "Error copying file: $_" -ForegroundColor Yellow
        return $false
    } finally {
        # Check for timeout (simulate timeout check)
        $ElapsedTime = ([DateTime]::Now - $StartTime).TotalSeconds
        if ($ElapsedTime -ge 10) { # Adjust timeout as needed
            Write-Host "Timeout reached for file: $SourceFile" -ForegroundColor Red
        }
    }
}

# Process files in batches, with Ctrl+C support
try {
    Get-ChildItem -Path $SourceDir -File | ForEach-Object {
        $File = $_

        # Skip already processed files
        if ($File.FullName -in $ProcessedFiles) {
            Write-Host "SKIPPED: $($File.Name) (Already processed)" -ForegroundColor Yellow
            return
        }

        # Attempt to copy the file
        $Success = Safe-Copy -SourceFile $File.FullName -DestinationDir $DestDir
        if ($Success) {
            Write-Host "SUCCESS: $($File.Name)" -ForegroundColor Green
            "$($File.FullName),Success" | Out-File -Append -FilePath $LogFile
        } else {
            Write-Host "FAIL: $($File.Name)" -ForegroundColor Red
            "$($File.FullName),Fail" | Out-File -Append -FilePath $FailedLogFile
        }
    }
} catch {
    Write-Host "Script interrupted by user." -ForegroundColor Yellow
} finally {
    Write-Host "Script terminated." -ForegroundColor Cyan
}
