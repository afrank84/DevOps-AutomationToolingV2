# Retrieve OS information from the registry
$osInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

# Retrieve detailed version information from .NET
$osVersion = [System.Environment]::OSVersion.Version

# Combine the information into a string
$output = "ProductName: $($osInfo.ProductName), ReleaseId: $($osInfo.ReleaseId), CurrentBuild: $($osInfo.CurrentBuild), Version: $osVersion"

# Write output to a text file in the current directory
$outputFile = Join-Path (Get-Location) "OSInfo.txt"
$output | Out-File -FilePath $outputFile -Encoding UTF8

# Print a confirmation message
Write-Host "OS information saved to $outputFile"
