function Get-JiraIssuesWithSummaryAndKey {
    param(
        [string]$SearchTerm
    )

    # Jira Cloud instance URL, Username, and API token or password from environment variables
    $JiraUrl = $env:JIRA_URL
    $Username = $env:JIRA_USERNAME
    $Password = $env:JIRA_API

    # The project key
    $projectKey = "KC"

    # Today's date in Jira's date format (yyyy-MM-dd)
    $today = Get-Date -Format "yyyy-MM-dd"

    # Encode credentials
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$Username`:$Password")))

    # Set request headers
    $headers = @{
        Authorization=("Basic {0}" -f $base64AuthInfo)
        "Content-Type"="application/json"
    }

    # Jira API endpoint with JQL to get issues from a project with specific criteria
    $apiUrl = "$JiraUrl/rest/api/3/search?jql=project=$projectKey AND created >= '$today' AND summary ~ '$SearchTerm'"

    # Send the request to Jira API
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers
    } catch {
        Write-Error "Error in fetching Jira issues: $_"
        return
    }

    # Output the response with issue key (ticket ID) and summary
    $response.issues | ForEach-Object {
        Write-Output ("Issue Key: {0}, Summary: {1}" -f $_.key, $_.fields.summary)
    }
}

# Example usage
Get-JiraIssuesWithSummaryAndKey -SearchTerm "Raynor"
Get-JiraIssuesWithSummaryAndKey -SearchTerm "Aurora"
