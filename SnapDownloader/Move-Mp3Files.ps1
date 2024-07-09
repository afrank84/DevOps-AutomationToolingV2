function Move-Mp3Files {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder
    )

    # Create the destination folder if it doesn't exist
    if (!(Test-Path -Path $DestinationFolder)) {
        New-Item -ItemType Directory -Force -Path $DestinationFolder
    }

    # Get all MP3 files from the source folder
    $mp3Files = Get-ChildItem -Path $SourceFolder -Filter "*.mp3" -File

    # Move each MP3 file to the destination folder
    foreach ($file in $mp3Files) {
        $destinationPath = Join-Path -Path $DestinationFolder -ChildPath $file.Name
        Move-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "$file MP3 file(s) moved to $DestinationFolder."
    }

    # Output the number of files moved
    Write-Host "$($mp3Files.Count) MP3 file(s) moved to $DestinationFolder."
}

Move-Mp3Files -SourceFolder "D:\Videos\SnapDownloader" -DestinationFolder "D:\Music"
