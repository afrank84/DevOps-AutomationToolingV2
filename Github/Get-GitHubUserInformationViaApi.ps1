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
