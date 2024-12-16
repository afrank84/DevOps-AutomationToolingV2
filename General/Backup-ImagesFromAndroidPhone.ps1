# Define source, destination, and log files
$SourceDir = "E:\DCIM\Camera"
$DestDir = "D:\00-SamsungBackup\Images\Camera"
$LogFile = "D:\00-SamsungBackup\transfer_log.txt"
$FailedLogFile = "D:\00-SamsungBackup\failed_files_log.txt"

# Function to convert file size to a human-readable format
function Format-FileSize {
    param ([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    else { return "$Bytes Bytes" }
}

# Preload processed files into a hash table
$ProcessedFiles = @{}
if (Test-Path $LogFile) {
    Get-Content $LogFile | ForEach-Object {
        $FilePath = ($_ -split ',')[0]
        $ProcessedFiles[$FilePath] = $true
    }
}
if (Test-Path $FailedLogFile) {
    Get-Content $FailedLogFile | ForEach-Object {
        $FilePath = ($_ -split ',')[0]
        $ProcessedFiles[$FilePath] = $true
    }
}

# Function to safely copy a file with size display
function Safe-Copy {
    param (
        [string]$SourceFile,
        [string]$DestinationDir
    )
    $StartTime = [DateTime]::Now
    $FileSize = (Get-Item -Path $SourceFile).Length
    $FormattedSize = Format-FileSize -Bytes $FileSize

    Write-Host "Processing: $SourceFile ($FormattedSize)" -ForegroundColor Cyan

    try {
        Copy-Item -Path $SourceFile -Destination $DestinationDir -ErrorAction Stop
        return $true
    } catch {
        Write-Host "Error copying file: $_" -ForegroundColor Yellow
        return $false
    }
}

# Process files
try {
    Get-ChildItem -Path $SourceDir -File | ForEach-Object {
        $File = $_

        # Skip already processed files
        if ($ProcessedFiles.ContainsKey($File.FullName)) {
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
