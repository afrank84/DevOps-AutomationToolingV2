# Get the computer name
$ComputerName = (Get-ComputerInfo -Property CsName).CsName

# Specify the default file name with the computer name
$FileName = "$ComputerName-UpdateHistory.txt"

# Function to detect connected USB drives
function Get-USBDrive {
    Get-WmiObject -Query "Select * from Win32_LogicalDisk Where DriveType=2" | Select-Object -ExpandProperty DeviceID
}

# Check for connected USB drives
$USBDrives = Get-USBDrive

# Determine the target path
if ($USBDrives) {
    # Use the first detected USB drive
    $USBDrive = $USBDrives | Select-Object -First 1
    $OutputFile = Join-Path -Path $USBDrive -ChildPath $FileName
    Write-Output "USB drive detected: $USBDrive. Saving update history to $OutputFile."
} else {
    # Default to saving in the current directory
    $OutputFile = (Join-Path -Path (Get-Location) -ChildPath $FileName)
    Write-Output "No USB drive detected. Saving update history to $OutputFile."
}

# Create an update session
$Session = [Activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))

# Create an update searcher
$Searcher = $Session.CreateUpdateSearcher()

# Get the total number of updates in the history
$HistoryCount = $Searcher.GetTotalHistoryCount()

# Check if there is any update history
if ($HistoryCount -gt 0) {
    # Retrieve the update history
    $UpdateHistory = $Searcher.QueryHistory(0, $HistoryCount)

    # Create or overwrite the output file
    Set-Content -Path $OutputFile -Value "Windows Update History for $ComputerName:`n"

    # Iterate through the update history and display details
    foreach ($Update in $UpdateHistory) {
        $UpdateDetails = @"
Title: $($Update.Title)
Description: $($Update.Description)
Installation Date: $($Update.Date)
Status: $($Update.ResultCode)
----------------------------------
"@
        # Write details to the console (verbose output)
        Write-Output $UpdateDetails

        # Append details to the output file
        Add-Content -Path $OutputFile -Value $UpdateDetails
    }

    Write-Output "Update history has been saved to $OutputFile."
} else {
    $Message = "No update history found on this system."
    
    # Write message to the console
    Write-Output $Message
    
    # Write message to the output file
    Set-Content -Path $OutputFile -Value $Message
}
