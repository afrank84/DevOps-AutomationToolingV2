# Define variables
$baseURL = "https://your-jira-instance.atlassian.net"
$projectKey = "YOUR_PROJECT_KEY"
$username = "your-email@example.com"
$apiToken = "your-api-token"

# Base64 encode the username and API token for authorization
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${apiToken}")))

# Create a function to get all issues for a project
function Get-JiraIssues($projectKey) {
    $issues = @()
    $startAt = 0
    $maxResults = 200  # Adjust this value as needed

    do {
        $url = "$baseURL/rest/api/3/search?jql=project=$projectKey&startAt=$startAt&maxResults=$maxResults&fields=attachment"
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ Authorization = "Basic $authInfo" }
        $issues += $response.issues
        $startAt += $maxResults
    } while ($response.total -gt $startAt)

    return $issues
}

# Create a function to list attachments
function List-Attachments($issues) {
    $attachmentList = @()

    foreach ($issue in $issues) {
        foreach ($attachment in $issue.fields.attachment) {
            $attachmentInfo = @{
                "Issue Key" = $issue.key
                "Attachment Filename" = $attachment.filename
                "Attachment URL" = $attachment.content
                "Attachment Size" = $attachment.size
                "Created" = $attachment.created
            }
            $attachmentList += $attachmentInfo
        }
    }

    return $attachmentList
}

# Get all issues for the project
$issues = Get-JiraIssues -projectKey $projectKey

# List all attachments
$attachments = List-Attachments -issues $issues

# Display the attachment list
$attachments | Format-Table -AutoSize
