# Define your Jira credentials and issue key
$JiraUrl =  $env:JIRA_URL # Replace with your Jira URL
$Username = $env:JIRA_USERNAME # Replace with your Jira username
$Password = $env:JIRA_API
$IssueKey = "KC-29" # Replace with the key of the issue you want to delete

# Base64 encode your credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${Username}:${Password}")))

# Set up the REST API URL for deleting the issue
$DeleteIssueUrl = "${JiraUrl}/rest/api/2/issue/${IssueKey}"

# Define headers for the API request
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

# Send the DELETE request to delete the issue
try {
    Invoke-RestMethod -Uri $DeleteIssueUrl -Headers $headers -Method Delete
    Write-Host "Issue $IssueKey has been deleted successfully."
}
catch {
    Write-Host "Error deleting issue: $($_.Exception.Message)"
}
