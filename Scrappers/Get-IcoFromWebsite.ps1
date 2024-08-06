# Define the website URL
$websiteUrl = "https://github.com"

# Send a web request to the website
$response = Invoke-WebRequest -Uri $websiteUrl

# Extract the favicon URL from the response
$faviconUrl = $response.Links | Where-Object { $_.href -match 'favicon.ico' } | Select-Object -ExpandProperty href

# If the favicon URL is a relative path, convert it to an absolute URL
if ($faviconUrl -notmatch "^https?://") {
    $faviconUrl = [Uri]::new($websiteUrl, $faviconUrl).AbsoluteUri
}

# Define the output path for the .ico file
$outputPath = ""

# Download the favicon
Invoke-WebRequest -Uri $faviconUrl -OutFile $outputPath

Write-Output "Favicon downloaded to $outputPath"
