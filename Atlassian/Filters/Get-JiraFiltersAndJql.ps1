# Function to read credentials from a text file
function Get-Credentials {
    param (
        [string]$FilePath
    )

    $credentials = @{}

    foreach ($line in Get-Content $FilePath) {
        if ($line -match '^\s*#' -or $line.Trim() -eq "") {
            continue
        }

        if ($line -match '^(.*)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $credentials[$key] = $value
        }
    }

    return $credentials
}

# Replace with the path to your credentials file
$credentialsFilePath = "Data\credentials4.txt"

# Get credentials
$credentials = Get-Credentials -FilePath $credentialsFilePath

# Assign credentials to variables
$JiraEmail = $credentials["cloudEmail"]
$JiraApiToken = $credentials["cloudApiToken"] #Not working, had to do this one manually. 
$JiraBaseUrl = $credentials["cloudProductionUrl"] # Using cloudProductionUrl instead of cloudSandboxUrl

# Debugging output to check if credentials are read correctly
Write-Host "JiraEmail: $JiraEmail"
Write-Host "JiraApiToken: $JiraApiToken"
Write-Host "JiraBaseUrl: $JiraBaseUrl"

# Ensure JiraBaseUrl does not end with a slash
if ($JiraBaseUrl.EndsWith("/")) {
    $JiraBaseUrl = $JiraBaseUrl.TrimEnd("/")
}

# Check if the necessary credentials are provided
if (-not $JiraEmail -or -not $JiraApiToken -or -not $JiraBaseUrl) {
    Write-Error "Please ensure that cloudEmail, cloudApiToken, and cloudProductionUrl are provided in the credentials file."
    exit 1
}

# Create the authentication header
$authHeader = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($JiraEmail):$($JiraApiToken)"))
}

# Function to get all filters
function Get-JiraFilters {
    param (
        [string]$BaseUrl,
        [hashtable]$Headers
    )

    $url = "$($BaseUrl)/rest/api/3/filter/search"
    $filters = @()
    $detailedFilters = @()

    try {
        # Initial request to get total number of filters
        $response = Invoke-RestMethod -Uri $url -Headers $Headers
    }
    catch {
        Write-Error "Failed to fetch filters: $($_.Exception.Message)"
        exit 1
    }

    $totalFilters = $response.total
    $startAt = 0
    $maxResults = 50

    while ($startAt -lt $totalFilters) {
        $url = "$($BaseUrl)/rest/api/3/filter/search?startAt=$($startAt)&maxResults=$($maxResults)"
        try {
            $response = Invoke-RestMethod -Uri $url -Headers $Headers
        }
        catch {
            Write-Error "Failed to fetch filters at startAt=$($startAt): $($_.Exception.Message)"
            exit 1
        }

        foreach ($filter in $response.values) {
            $filters += $filter

            # Fetch detailed information for each filter
            $filterDetailsUrl = "$($BaseUrl)/rest/api/3/filter/$($filter.id)"
            try {
                $filterDetails = Invoke-RestMethod -Uri $filterDetailsUrl -Headers $Headers
                $detailedFilters += [PSCustomObject]@{
                    Id = $filterDetails.id
                    Name = $filterDetails.name
                    JQL = $filterDetails.jql
                    Owner = $filterDetails.owner.displayName
                }
            }
            catch {
                Write-Error "Failed to fetch details for filter ID $($filter.id): $($_.Exception.Message)"
            }
        }

        $startAt += $maxResults
    }

    return $detailedFilters, $response
}

# Get all filters
$detailedFilters, $response = Get-JiraFilters -BaseUrl $JiraBaseUrl -Headers $authHeader

# Save the raw JSON response to a file with a timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFilePath = "JiraFilters_$timestamp.json"
$response | ConvertTo-Json | Out-File -FilePath $jsonFilePath

Write-Host "JSON response saved to $jsonFilePath"

# Output filters with JQL as a code block
foreach ($filter in $detailedFilters) {
    Write-Host "Filter ID: $($filter.Id)"
    Write-Host "Name: $($filter.Name)"
    Write-Host "Owner: $($filter.Owner)"
    Write-Host "JQL: `n$($filter.JQL)`n"
    Write-Host "----------------------------------"
}

# Optionally, you can export the results to a CSV file
$detailedFilters | Export-Csv -Path "JiraFilters.csv" -NoTypeInformation
