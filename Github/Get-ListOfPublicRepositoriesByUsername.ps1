# Prompt the user for a GitHub username
$username = Read-Host -Prompt "Enter the GitHub username"

# Define the GitHub API URL for the user's public repositories
$url = "https://api.github.com/users/$username/repos"

# Make the API request and get the response
$response = Invoke-RestMethod -Uri $url -Method Get

# Check if the response is not empty
if ($response) {
    # Loop through each repository in the response
    foreach ($repo in $response) {
        # Output the repository name and URL
        Write-Output "Name: $($repo.name)"
        Write-Output "URL: $($repo.html_url)"
        Write-Output ""
    }
} else {
    Write-Output "No repositories found for user: $username"
}
