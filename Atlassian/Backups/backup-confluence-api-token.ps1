# Set Atlassian API credentials, headers, and other specifics
$email = “yourEmailAddressHere”
$apiToken = “yourTokenHere”
#See how to create an API token: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/
$domain = “subDomainNameHere.atlassian.net"
$attachments = 'false' # Tells the script whether or not to pull down the attachments as well
$cloud     = 'true' # Tells the script whether to export the backup for Cloud or Server
$destination = 'C:\Backups\Confluence\' # Location on server where script is run to dump the backup zip file.
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($email):$($apiToken)"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

#Check of destination folder, create is missing
if(!(Test-Path -path $destination)){
write-host "Folder is not present, creating folder"
mkdir $destination #Make the path and folder is not present
}
else{
write-host "Path is already present"
}

#Set body
$body = @{
          cbAttachments=$attachments
          exportToCloud=$cloud
         }
$bodyjson = $body | ConvertTo-Json

# Set Atlassian Cloud backup endpoint
$backupEndpoint = "https://$domain/wiki/rest/obm/1.0/runbackup"
$backupStatusURL = "https://$domain/wiki/rest/obm/1.0/getprogress"


# Create a Confluence Cloud backup
$backupResponse = Invoke-WebRequest -Method POST -Uri $backupEndpoint -Headers $headers -Body $bodyjson


# Check if backup creation was successful
if ($backupResponse.StatusCode -eq 200) {

    # Wait for the backup to be ready
    $backupReady = $false
    while (!$backupReady) {
        Write-Host "We're waiting 60 seconds to check the status of your backup."
        Start-Sleep -Seconds 60
        #Get Backup Session ID
        $backupStatus = Invoke-WebRequest -Method GET -Headers $headers $backupStatusURL
        $statusResponse = $backupStatus
        $statusContent = $statusResponse.Content | ConvertFrom-Json
        $backupStatusOutput = $statusContent.alternativePercentage
        $backupReady = $statusContent.alternativePercentage -eq "100%"
        Write-Host "Current backup status is $($backupStatusOutput)"
    }

     #Identify file locaiton to download
    $parseResults = $backupStatus.Content | ConvertFrom-Json
    $backupLocation = $parseResults.fileName
    # Download the backup file
    $backupUrl = "https://$domain/wiki/download/$backupLocation"
    $backupFilename = "confluence-backup-$(Get-Date -Format "yyyyMMdd").zip"
    Invoke-WebRequest -Method Get -Uri $backupUrl -Headers $headers -OutFile $destination$backupFilename
    Write-Host "Backup saved as $backupFilename"
} else {
    Write-Host "Error: Failed to create Confluence backup. Status code: $($backupResponse.StatusCode)"
} 
