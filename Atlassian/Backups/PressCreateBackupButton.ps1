$Username = "your_username"
$Password = "your_password" #PAT token is fine
$JiraInstanceUrl = "https://your-address-here"

# Encode credentials to base64 for Basic Auth
$EncodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Username):$($Password)"))

# Define the payload
$Payload = @{
    cbAttachments = "false"
    exportToCloud = "true"
} | ConvertTo-Json

# Trigger the backup
$response = Invoke-RestMethod -Uri "$($JiraInstanceUrl)/rest/backup/1/export/runbackup" -Method Post -Headers @{
    Authorization = "Basic $($EncodedCreds)"
    "Content-Type" = "application/json"
} -Body $Payload

# Check the response
if ($response) {
    Write-Host "Backup triggered successfully!"
} else {
    Write-Host "Failed to trigger backup."
}
