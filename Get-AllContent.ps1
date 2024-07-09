function Copy-HtmlToMd {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$RootDirectory
    )

    # Get all HTML files recursively in the directory
    $htmlFiles = Get-ChildItem -Path $RootDirectory -Filter "*.html" -Recurse

    # Loop through each HTML file
    foreach ($file in $htmlFiles) {
        # Create the new file name with .md extension
        $newFileName = [System.IO.Path]::ChangeExtension($file.FullName, "md")

        # Copy the content of the HTML file to the new file
        Copy-Item -Path $file.FullName -Destination $newFileName -Force

        Write-Host "Created file: $newFileName"
    }
}


Copy-HtmlToMd -RootDirectory "D:\stash\DevOps-PowerShellAutomation\"
