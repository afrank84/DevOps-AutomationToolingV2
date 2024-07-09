# Function to convert .msg files in a directory to Markdown
function Convert-MSGFilesToMarkdown {
    param (
        [string]$sourceDirectory
    )

    # Load Outlook interop assembly
    Add-Type -AssemblyName Microsoft.Office.Interop.Outlook

    # Function to convert .msg to Markdown
    function Convert-MSGtoMarkdown {
        param (
            [string]$msgFilePath
        )

        # Create Outlook application object
        $outlook = New-Object -ComObject Outlook.Application

        # Open .msg file
        $msg = $outlook.Session.OpenSharedItem($msgFilePath)

        # Extract email properties
        $subject = $msg.Subject
        $body = $msg.Body

        # Close the .msg file
        $msg.Close([Microsoft.Office.Interop.Outlook.OlInspectorClose]::olDiscard)

        # Convert to Markdown format
        $markdownContent = "# $subject`n`n$body"

        return $markdownContent
    }

    # Get all .msg files in the specified directory
    $msgFiles = Get-ChildItem -Path $sourceDirectory -Filter *.msg

    # Iterate over each .msg file
    foreach ($msgFile in $msgFiles) {
        # Check if a converted Markdown file already exists
        $markdownFilePath = [System.IO.Path]::ChangeExtension($msgFile.FullName, ".md")
        if (-not (Test-Path $markdownFilePath)) {
            # Convert .msg to Markdown
            $markdownContent = Convert-MSGtoMarkdown -msgFilePath $msgFile.FullName

            # Write Markdown content to a new file
            Set-Content -Path $markdownFilePath -Value $markdownContent
            Write-Host "Converted $($msgFile.Name) to Markdown: $($markdownFilePath)"
        } else {
            Write-Host "Markdown file already exists for $($msgFile.Name)"
        }
    }
}

# Usage example
Convert-MSGFilesToMarkdown -sourceDirectory "C:\path\to\directory"
