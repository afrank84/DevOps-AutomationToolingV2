# Define paths
$serverPath = "C:\MinecraftServer"  # Path to your Minecraft server folder
$worldFolder = "$serverPath\world"  # Path to your Minecraft world folder
$backupDir = "C:\MinecraftBackups"  # Directory where backups will be saved
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"  # Timestamp for versioning

# Check if backup directory exists, create it if it doesn't
if (-not (Test-Path -Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir
}

# Define the backup file name with timestamp
$backupFile = "$backupDir\minecraft_backup_$timestamp.zip"

# Zip the world folder into the backup directory
Write-Host "Creating a backup of your Minecraft world..."
Compress-Archive -Path $worldFolder -DestinationPath $backupFile -Force

# Provide feedback on completion
if (Test-Path -Path $backupFile) {
    Write-Host "Backup successful: $backupFile"
} else {
    Write-Host "Backup failed."
}

# Optional: Remove old backups (older than 7 days)
$daysToKeep = 7
Get-ChildItem $backupDir -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$daysToKeep) } | Remove-Item -Force

Write-Host "Old backups older than $daysToKeep days removed."
