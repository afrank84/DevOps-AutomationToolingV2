# Specify the path to your MP3 file
$mp3FilePath = "C:\Path\To\Your\File.mp3"

# Load the necessary .NET assemblies for working with ID3 tags
Add-Type -TypeDefinition @"
using System;
using System.IO;
using TagLib;
"@

# Function to extract and list images from MP3 metadata
Function Get-MP3Images {
    param (
        [string]$mp3Path
    )

    try {
        # Open the MP3 file
        $file = [TagLib.File]::Create($mp3Path)

        # Get all the attached pictures (cover art)
        $pictures = $file.Tag.Pictures

        if ($pictures.Count -gt 0) {
            Write-Host "Images found in $mp3Path:"
            $pictureCount = 1
            foreach ($picture in $pictures) {
                $imageType = $picture.MimeType
                $imageName = "Image_$pictureCount.$($imageType.Split('/')[1])"
                $picture.Save("C:\Path\To\Save\Images\$imageName")
                Write-Host "Image $pictureCount: $imageName"
                $pictureCount++
            }
        }
        else {
            Write-Host "No images found in $mp3Path."
        }
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}

# Call the function with the specified MP3 file
Get-MP3Images -mp3Path $mp3FilePath
