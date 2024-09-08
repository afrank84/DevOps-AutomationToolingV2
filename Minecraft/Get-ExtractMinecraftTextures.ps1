# Define variables
$version = Read-Host "Enter the Minecraft version (e.g., 1.20)"
$minecraftDir = "$env:APPDATA\.minecraft\versions\$version"
$jarFile = "$minecraftDir\$version.jar"
$destinationDir = "$env:USERPROFILE\Documents\Minecraft_Default_Textures_$version"
$tempExtractDir = "$env:TEMP\MinecraftTextures"

# Check if the version jar file exists
if (-Not (Test-Path $jarFile)) {
    Write-Host "The specified Minecraft version ($version) does not exist. Please check and try again." -ForegroundColor Red
    exit
}

# Create destination directory if it doesn't exist
if (-Not (Test-Path $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir
}

# Create a temporary folder for extraction
if (-Not (Test-Path $tempExtractDir)) {
    New-Item -ItemType Directory -Path $tempExtractDir
}

# Extract the jar file
Write-Host "Extracting Minecraft $version jar file..."
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::ExtractToDirectory($jarFile, $tempExtractDir)

# Copy the textures to the destination folder
$sourceTexturesDir = "$tempExtractDir\assets\minecraft\textures"
if (Test-Path $sourceTexturesDir) {
    Write-Host "Copying textures to $destinationDir..."
    Copy-Item -Recurse -Path $sourceTexturesDir -Destination $destinationDir
    Write-Host "Textures extracted successfully to $destinationDir" -ForegroundColor Green
} else {
    Write-Host "Could not find textures in the specified version's jar file." -ForegroundColor Red
}

# Clean up temporary extraction directory
Remove-Item -Recurse -Force $tempExtractDir

Write-Host "Process completed!"
