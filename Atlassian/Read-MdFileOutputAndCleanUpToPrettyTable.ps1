# Define the path to the input file
$filePath = "C:\path\to\your\inputfile.txt"

# Read the content of the file
$data = Get-Content -Path $filePath

# Create an array to hold the parsed data
$parsedData = @()

# Parse each line
foreach ($line in $data) {
    if ($line -match "issue key:\s*(\S+)\s*file name:\s*(.+)") {
        $parsedData += [PSCustomObject]@{
            IssueKey = $matches[1]
            FileName = $matches[2]
        }
    }
}

# Print the organized data as a table
$parsedData | Format-Table -AutoSize
