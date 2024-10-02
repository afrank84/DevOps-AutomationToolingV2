# Artifactory server URL
$artifactoryUrl = "https://your-artifactory-instance.com/artifactory"

# Full repository path (including repository name and folder path)
$repositoryPath = "your-repository/path/to/your/folder"

# Artifactory API endpoint
$apiEndpoint = "$artifactoryUrl/api/storage/$repositoryPath"

# Artifactory API key
$apiKey = "your-api-key"

# Set up headers
$headers = @{
    "X-JFrog-Art-Api" = $apiKey
}

# Make the API request
try {
    $response = Invoke-RestMethod -Uri $apiEndpoint -Headers $headers -Method Get
    
    # Display the list of files with their sizes
    foreach ($file in $response.children) {
        if (-not $file.folder) {
            # Construct the correct URL for file info
            $fileInfoUrl = "$apiEndpoint$($file.uri)"
            $fileInfo = Invoke-RestMethod -Uri $fileInfoUrl -Headers $headers -Method Get
            $sizeInMB = [math]::Round($fileInfo.size / 1MB, 2)
            Write-Output "$($file.uri) - Size: $sizeInMB MB"
        }
    }
}
catch {
    Write-Error "An error occurred: $_"
}
