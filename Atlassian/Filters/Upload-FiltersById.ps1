# Function to read Jira credentials from a text file
function Get-JiraCredentials {
    param (
        [string]$credentialsPath
    )
    
    if (-Not (Test-Path -Path $credentialsPath)) {
        Throw "Credentials file not found: $credentialsPath"
    }

    $credentials = Get-Content -Path $credentialsPath -Raw | ConvertFrom-Json
    return $credentials
}

# Read Jira credentials
$credentialsPath = "$PSScriptRoot\jira_credentials.txt"
$jiraCredentials = Get-JiraCredentials -credentialsPath $credentialsPath
$jiraBaseUrl = $jiraCredentials.jiraBaseUrl
$jiraAuthToken = $jiraCredentials.jiraAuthToken

# Function to create a Jira filter
function Create-JiraFilter {
    param (
        [string]$filterName,
        [string]$jql,
        [string]$description
    )

    if (-Not $filterName) { Throw "Filter name cannot be empty" }
    if (-Not $jql) { Throw "JQL cannot be empty" }
    if (-Not $description) { Throw "Description cannot be empty" }

    $body = @{
        name             = $filterName
        jql              = $jql
        description      = $description
        sharePermissions = @(@{ type = "group"; group = @{ name = "jira-users" } })
    } | ConvertTo-Json -Depth 5

    $url = "$jiraBaseUrl/rest/api/3/filter"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $url -Headers @{
            "Authorization" = "Basic $jiraAuthToken"
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        } -Body $body
    }
    catch {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
        $ErrResp.errorMessages | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
        $streamReader.Close()
        Throw "Failed to create filter '$filterName'"
    }

    return $response.id
}

# Function to assign filter ownership
function Assign-JiraFilterOwner {
    param (
        [string]$filterId,
        [string]$accountId
    )

    if (-Not $filterId) { Throw "Filter ID cannot be empty" }
    if (-Not $accountId) { Throw "Account ID cannot be empty" }

    $body = @{
        accountId = $accountId
    } | ConvertTo-Json

    $url = "$jiraBaseUrl/rest/api/3/filter/$filterId/owner"
    try {
        Invoke-RestMethod -Method Put -Uri $url -Headers @{
            "Authorization" = "Basic $jiraAuthToken"
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        } -Body $body
    }
    catch {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
        $ErrResp.errorMessages | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
        $streamReader.Close()
        Throw "Failed to assign filter '$filterId' to account ID '$accountId'"
    }
}

# Read the JSON file containing filter data
$jsonFilePath = "$PSScriptRoot\FiltersByUserAccount_TestUpload.json"
if (-Not (Test-Path -Path $jsonFilePath)) {
    Throw "JSON file not found: $jsonFilePath"
}
$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

$createdFilters = @()

# Process each user and their filters
foreach ($user in $jsonContent) {
    $accountId = $user.accountId
    foreach ($filter in $user.filters) {
        $filterName = $filter.filterName
        $query = $filter.query
        $description = "Filter created for $($user.displayName)"

        try {
            # Create the filter and get its ID
            $filterId = Create-JiraFilter -filterName $filterName -jql $query -description $description
            $createdFilters += $filterId

            # Assign the filter to the user
            Assign-JiraFilterOwner -filterId $filterId -accountId $accountId

            Write-Host "Filter '$filterName' has been created and assigned to user '$($user.displayName)'" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }
}

Write-Host "Filters have been created and assigned successfully." -ForegroundColor Blue

# Write the created filters to a file
$createdFilters | ConvertTo-Json | Set-Content -Path "$PSScriptRoot\CreatedFilters.json"
