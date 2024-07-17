Sure! Here's a README for the PowerShell function `Get-GitHubUserInfo`.

# Get-GitHubUserInfo PowerShell Function

## Overview

`Get-GitHubUserInfo` is a PowerShell function that fetches information about a specified GitHub user using the GitHub API. The function allows you to output the fetched data either in a readable format or as JSON.

## Prerequisites

- PowerShell 5.1 or later
- Internet connection

## Usage

1. Copy the `Get-GitHubUserInfo` function into your PowerShell script or profile.
2. Run the script and follow the prompts to enter the GitHub username and whether you want the output in JSON format.

### Example

To use the function, open PowerShell and run the script containing the function. You will be prompted to enter the GitHub username and whether you want the output in JSON format.

```powershell
# Save this script as Get-GitHubUserInfo.ps1 and run it in PowerShell

function Get-GitHubUserInfo {
    param (
        [string]$user = $(Read-Host -Prompt 'Enter the GitHub username'),
        [switch]$json = $(Read-Host -Prompt 'Output in JSON format? (y/n)').ToLower() -eq 'y'
    )

    $API_URL = "https://api.github.com"
    $response = Invoke-RestMethod -Uri "$API_URL/users/$user"

    if ($json) {
        $response | ConvertTo-Json -Depth 10
    } else {
        foreach ($property in $response.PSObject.Properties) {
            Write-Output "$($property.Name): $($property.Value)"
        }
    }
}

# Call the function
Get-GitHubUserInfo
```

### Prompts

- **Enter the GitHub username**: Enter the username of the GitHub user you want to look up.
- **Output in JSON format? (y/n)**: Type `y` if you want the output in JSON format, or `n` for a readable format.

### Example Output

For a user named `octocat`, the function might output:

```plaintext
Enter the GitHub username: octocat
Output in JSON format? (y/n): n

login: octocat
id: 583231
node_id: MDQ6VXNlcjU4MzIzMQ==
avatar_url: https://avatars.githubusercontent.com/u/583231?v=4
gravatar_id: 
url: https://api.github.com/users/octocat
html_url: https://github.com/octocat
followers_url: https://api.github.com/users/octocat/followers
following_url: https://api.github.com/users/octocat/following{/other_user}
gists_url: https://api.github.com/users/octocat/gists{/gist_id}
starred_url: https://api.github.com/users/octocat/starred{/owner}{/repo}
subscriptions_url: https://api.github.com/users/octocat/subscriptions
organizations_url: https://api.github.com/users/octocat/orgs
repos_url: https://api.github.com/users/octocat/repos
events_url: https://api.github.com/users/octocat/events{/privacy}
received_events_url: https://api.github.com/users/octocat/received_events
type: User
site_admin: false
name: The Octocat
company: GitHub
blog: https://github.blog
location: San Francisco
email: 
hireable: 
bio: 
twitter_username: 
public_repos: 8
public_gists: 8
followers: 3934
following: 9
created_at: 2011-01-25T18:44:36Z
updated_at: 2020-07-01T17:46:50Z
```

### JSON Output

If you choose JSON format by typing `y`, the output will be a JSON string representing the user data.

## License

This script is released under the MIT License. Feel free to use, modify, and distribute it as you see fit.

## Contributions

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## Contact

For any questions or comments, feel free to contact the author.

---

Feel free to customize this README further according to your needs.
