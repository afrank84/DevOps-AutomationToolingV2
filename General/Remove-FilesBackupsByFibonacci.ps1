# Configuration
$backupFolder = "D:\Confluence_Backups" # Path to the backup folder
$fibonacciMaxDays = 233                 # Maximum Fibonacci interval in days to retain backups

# Generate Fibonacci sequence up to the max days
function Get-Fibonacci {
    param([int]$max)
    $a = 0
    $b = 1
    $fibs = @()
    while ($b -le $max) {
        $fibs += $b
        $temp = $a + $b
        $a = $b
        $b = $temp
    }
    return $fibs
}

$fibonacciDays = Get-Fibonacci -max $fibonacciMaxDays
Write-Output "Fibonacci intervals to retain: $fibonacciDays"

# Get current date
$currentDate = Get-Date

# Get all directories in the backup folder
$backupDirectories = Get-ChildItem -Path $backupFolder -Directory | Sort-Object Name

# Retain backups based on Fibonacci intervals
foreach ($dir in $backupDirectories) {
    if ($dir.Name -match '\d{8}') {
        $backupDate = [datetime]::ParseExact($matches[0], "yyyyMMdd", $null)
        $daysAgo = ($currentDate - $backupDate).Days

        if ($daysAgo -eq 0 -or $fibonacciDays -contains $daysAgo) {
            Write-Output "Retaining backup: $($dir.FullName) (Created $daysAgo days ago)"
        } else {
            Write-Output "Deleting backup: $($dir.FullName) (Created $daysAgo days ago)"
            Remove-Item -Path $dir.FullName -Recurse -Force
        }
    } else {
        Write-Output "Skipping non-date folder: $($dir.FullName)"
    }
}
