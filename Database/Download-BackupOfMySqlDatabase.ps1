<#
.SYNOPSIS
    This script backs up a MySQL database to a specified folder with a timestamped filename.

.DESCRIPTION
    The script connects to a MySQL database, creates a backup file in SQL format, 
    and optionally cleans up old backups to keep the folder tidy. It generates a 
    timestamped filename for each backup to avoid overwriting previous ones.

.PARAMETER Host
    The hostname or IP address of the MySQL server (default is "localhost").

.PARAMETER User
    The MySQL username with access to the database.

.PARAMETER Password
    The password for the MySQL user.

.PARAMETER Database
    The name of the database to back up.

.PARAMETER BackupFolder
    The folder where the backup files will be saved (default is "C:\DatabaseBackups").

.EXAMPLE
    .\Download-DatabaseBackup.ps1 -Host "mydbserver.com" -User "admin" -Password "secretpassword" -Database "production_db" -BackupFolder "D:\MyBackups"
    This will back up the "production_db" database on "mydbserver.com" to "D:\MyBackups" with a timestamped file.

.NOTES
    Make sure the MySQL client (mysqldump) is installed and accessible in the system's PATH.
    This script is designed for MySQL databases; adjust the command for other databases if necessary.
#>

# Define parameters
param (
    [string]$Host = "localhost",          # Hostname or IP address of the MySQL server
    [string]$User = "root",               # MySQL username
    [string]$Password = "password",       # MySQL user password
    [string]$Database = "mydatabase",     # Database name to back up
    [string]$BackupFolder = "C:\DatabaseBackups" # Folder to save backups
)

# Step 1: Create backup folder if it doesn't exist
if (!(Test-Path -Path $BackupFolder)) {
    Write-Output "Creating backup folder at $BackupFolder"
    New-Item -ItemType Directory -Path $BackupFolder
}

# Step 2: Generate a timestamped filename for the backup
$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BackupFile = Join-Path -Path $BackupFolder -ChildPath "$Database`_$Timestamp.sql"

# Step 3: Construct and run the mysqldump command
$DumpCommand = "mysqldump --host=$Host --user=$User --password=$Password $Database > `"$BackupFile`""
try {
    Write-Output "Starting database backup for '$Database' on host '$Host'..."
    Invoke-Expression $DumpCommand  # Execute the backup command

    # Step 4: Verify if the backup file was created successfully
    if (Test-Path -Path $BackupFile) {
        Write-Output "Database backup completed successfully: $BackupFile"
    } else {
        Write-Error "Database backup failed. Backup file not found."
    }
} catch {
    Write-Error "An error occurred during the database backup: $_"
}

# Step 5 (Optional): Cleanup old backups, keeping only the latest 7 files
# Adjust $MaxBackups to control how many backups are kept
$Backups = Get-ChildItem -Path $BackupFolder -Filter "$Database*.sql" | Sort-Object -Property LastWriteTime -Descending
$MaxBackups = 7
if ($Backups.Count -gt $MaxBackups) {
    $BackupsToDelete = $Backups | Select-Object -Skip $MaxBackups
    foreach ($Backup in $BackupsToDelete) {
        Remove-Item -Path $Backup.FullName -Force
        Write-Output "Deleted old backup: $($Backup.FullName)"
    }
}

Write-Output "Backup process completed."
