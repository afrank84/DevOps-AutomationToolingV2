# KC = Kids Chores
$JiraUrl = $env:JIRA_URL       # Replace with your Jira URL
$Username = $env:JIRA_USERNAME # Replace with your Jira username
$Password = $env:JIRA_API      # Replace with your Jira API token or password

# Base64 encode your credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${Username}:${Password}")))

# Set up the REST API URL for searching issues in Project KC with a status of "Done"
$SearchIssuesUrl = "${JiraUrl}/rest/api/2/search"

# Define the JQL query to find issues in Project KC with a status of "Done"
$JqlQuery = "project = KC AND status = Done"

# Define headers for the API request
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

# Send the POST request to search for issues
try {
    $searchData = @{
        "jql" = $JqlQuery
        "maxResults" = 1000  # Adjust the number of results per request as needed
    }
    
    $searchDataJson = $searchData | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $SearchIssuesUrl -Headers $headers -Method Post -Body $searchDataJson

    # Loop through the retrieved issues and delete them
    foreach ($issue in $response.issues) {
        $IssueKey = $issue.key
        $DeleteIssueUrl = "${JiraUrl}/rest/api/2/issue/${IssueKey}"
        
        # Send the DELETE request to delete the issue
        Invoke-RestMethod -Uri $DeleteIssueUrl -Headers $headers -Method Delete
        Write-Host "Issue $IssueKey has been deleted successfully."
    }
}
catch {
    Write-Host "Error searching or deleting issues: $($_.Exception.Message)"
}
