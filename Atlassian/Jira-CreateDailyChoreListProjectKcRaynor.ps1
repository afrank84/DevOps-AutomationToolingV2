# Define your Jira credentials
$JiraUrl = $env:JIRA_URL       # Replace with your Jira URL
$Username = $env:JIRA_USERNAME # Replace with your Jira username
$Password = $env:JIRA_API      # Replace with your Jira API token or password

# Base64 encode your credentials
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${Username}:${Password}")))

# Get the current date in the format "YYYY-MM-dd"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"

# Set up the REST API URL for creating an issue
$CreateIssueUrl = "${JiraUrl}/rest/api/2/issue/"

# Define headers for the API request
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

# Define the JSON data for creating the task, including the description and assignee
$descriptionText = @"
All chores must be done by 13:00 (1pm)

- Feed The Dogs
- Pick up Shoes
- Dishes (Empty or Fill)
- Bible Study w/ Dad
- Wipe Down Table
- Blow off concrete slab
- School work
- Empty Bathroom Trashcans
"@

# Replace "Child" with "Raynor" in the summary
$summaryText = "$CurrentDate Raynor Chores - PS"

# Specify the Jira username or email of the assignee ("Raynor Frank")
$assignee = "raynor.frank"  # Replace with the actual Jira username or email of Raynor Frank

$issueData = @{
    "fields" = @{
        "project" = @{
            "key" = "KC"   # Replace with the key of Project KC
        }
        "summary" = $summaryText       # Include the date in the summary with "Raynor"
        "issuetype" = @{
            "name" = "Task"          # Replace with the appropriate issue type
        }
        "description" = $descriptionText  # Include the list of chores and instructions in the description
        "assignee" = @{
            "name" = $assignee
        }
    }
}

# Convert the issue data to JSON format
$issueDataJson = $issueData | ConvertTo-Json

# Send the POST request to create the task
try {
    $response = Invoke-RestMethod -Uri $CreateIssueUrl -Headers $headers -Method Post -Body $issueDataJson

    $IssueKey = $response.key
    Write-Host "Task with key $IssueKey has been created and assigned to $assignee successfully."
}
catch {
    Write-Host "Error creating task: $($_.Exception.Message)"
}
