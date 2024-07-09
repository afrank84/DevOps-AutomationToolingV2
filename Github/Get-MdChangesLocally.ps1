function Search-MDFilesForLine {
    param (
        [string]$directoryToSearch = (Get-Location),
        [string]$lineToSearch = "github publish: true"
    )

    # Recursively search for .md files in the specified directory and its subdirectories
    $mdFiles = Get-ChildItem -Path $directoryToSearch -Filter *.md -Recurse

    # Loop through each .md file and search for the target line
    foreach ($file in $mdFiles) {
        $fileContent = Get-Content -Path $file.FullName -TotalCount 10
        if ($fileContent -match $lineToSearch) {
            # If the line is found, display the filename
            Write-Host $file.FullName -ForegroundColor green
        }
    }
}

# Example usage:
Search-MDFilesForLine -directoryToSearch "d:\stash\TheFrankEmpire\" -lineToSearch "github publish: true"
