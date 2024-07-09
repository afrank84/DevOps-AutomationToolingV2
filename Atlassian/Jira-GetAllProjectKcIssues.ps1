# Jira Cloud instance URL, Username, and API token or password from environment variables
$JiraUrl = $env:JIRA_URL
$Username = $env:JIRA_USERNAME
$Password = $env:JIRA_API

# The project key
$projectKey = "KC"

# Encode credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$Username`:$Password")))

# Set request headers
$headers = @{
    Authorization=("Basic {0}" -f $base64AuthInfo)
    "Content-Type"="application/json"
}

# Jira API endpoint to get issues from a project
$apiUrl = "$JiraUrl/rest/api/3/search?jql=project=$projectKey"

# Send the request to Jira API
$response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers

# Output the response
$response.issues | ForEach-Object {
    Write-Output $_.fields.summary
}
