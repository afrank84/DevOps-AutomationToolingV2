# Define your Jira credentials
$JiraUrl = $env:JIRA_URL       # Replace with your Jira URL
$Username = $env:JIRA_USERNAME # Replace with your Jira username
$Password = $env:JIRA_API      # Replace with your Jira API token or password

# Base64 encode your credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${Username}:${Password}")))

# Set up the REST API URL for searching issues in Project KC
$SearchIssuesUrl = "${JiraUrl}/rest/api/2/search"

# Update the JQL query to find issues in Project KC with "Aurora" or "Raynor" in the summary
$JqlQuery = 'project = KC AND (summary ~ "Aurora" OR summary ~ "Raynor")'

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

    # Loop through the retrieved issues and update their assignee based on the summary
    foreach ($issue in $response.issues) {
        $IssueKey = $issue.key
        $UpdateAssigneeUrl = "${JiraUrl}/rest/api/2/issue/${IssueKey}/assignee"

        if ($issue.fields.summary -like "*Aurora*") {
            # Aurora's accountId
            $assigneeData = @{
                "accountId" = "615a05f3d9820f007096daab" # Replace with Aurora's actual accountId
            }
        } elseif ($issue.fields.summary -like "*Raynor*") {
            # Raynor's accountId
            $assigneeData = @{
                "accountId" = "63972db83c9bcd363976e3d1" # Replace with Raynor's actual accountId
            }
        }

        $assigneeDataJson = $assigneeData | ConvertTo-Json

        # Send the PUT request to update the issue's assignee
        Invoke-RestMethod -Uri $UpdateAssigneeUrl -Headers $headers -Method Put -Body $assigneeDataJson
        Write-Host "Issue $IssueKey has been assigned."
    }
}
catch {
    Write-Host "Error searching or updating issues: $($_.Exception.Message)"
}
