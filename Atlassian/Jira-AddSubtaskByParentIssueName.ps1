function Add-SubtaskToIssue {
    param(
        [string]$ParentIssueKey,
        [string]$SubtaskSummary,
        [string]$SubtaskDescription
    )

    # Jira Cloud instance URL, Username, and API token or password from environment variables
    $JiraUrl = $env:JIRA_URL
    $Username = $env:JIRA_USERNAME
    $Password = $env:JIRA_API

    # Encode credentials
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("$Username`:$Password")))

    # Set request headers
    $headers = @{
        Authorization=("Basic {0}" -f $base64AuthInfo)
        "Content-Type"="application/json"
    }

    # Define the subtask data with the "Sub-task" issuetype explicitly
    $subtaskData = @{
        "fields" = @{
            "project" = @{
                "key" = $ParentIssueKey.Split("-")[0]  # Extract the project key from the parent issue key
            }
            "summary" = $SubtaskSummary
            "description" = $SubtaskDescription
            "issuetype" = @{
                "name" = "Sub-task"  # Use the name "Sub-task" for subtasks
            }
            "parent" = @{
                "key" = $ParentIssueKey
            }
        }
    }

    # Convert the subtask data to JSON
    $subtaskJson = $subtaskData | ConvertTo-Json

    # Jira API endpoint to create a subtask
    $apiUrl = "$JiraUrl/rest/api/3/issue/"

    # Send the request to create the subtask
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $subtaskJson
        Write-Output "Subtask created successfully with key $($response.key)"
    } catch {
        Write-Error "Error in creating subtask: $_"
    }
}

# Example usage to add a subtask to a specific parent issue
Add-SubtaskToIssue -ParentIssueKey "KC-52" -SubtaskSummary "Subtask 1" -SubtaskDescription "This is the first subtask"
