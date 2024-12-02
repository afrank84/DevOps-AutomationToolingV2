# Function to fetch details about multiple KBs from the Microsoft Update Catalog
function Get-KBDetailsBulk {
    param (
        [array]$KBIDs
    )

    # Construct the search URL for all KBs, separated by "+" for the catalog
    $query = ($KBIDs -join "+")
    $url = "https://www.catalog.update.microsoft.com/Search.aspx?q=$query"

    # Perform a web request
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing

    # Parse the HTML response to extract KB details
    if ($response.StatusCode -eq 200) {
        $html = $response.Content
        $result = @()

        # Extract each update's title and description
        $html -split "<tr>" | ForEach-Object {
            if ($_ -match '<a.*?>(KB\d+)<\/a>.*?>(.*?)<\/td>') {
                $result += [PSCustomObject]@{
                    KBID = $matches[1]
                    Title = $matches[2].Trim()
                }
            }
        }
        return $result
    } else {
        Write-Warning "Failed to fetch update details from the catalog."
        return $null
    }
}

# Step 1: Get all locally installed KBs
$hotfixes = Get-HotFix
$kbIDs = $hotfixes.HotFixID

# Step 2: Fetch details online for all KBs
$kbDetails = Get-KBDetailsBulk -KBIDs $kbIDs

# Step 3: Combine local and online data
if ($kbDetails) {
    $hotfixes | ForEach-Object {
        $onlineDetails = $kbDetails | Where-Object { $_.KBID -eq $_.HotFixID }
        [PSCustomObject]@{
            KBID          = $_.HotFixID
            Description   = $_.Description
            InstalledOn   = $_.InstalledOn
            OnlineDetails = $onlineDetails.Title
        }
    } | Format-Table -AutoSize
}
