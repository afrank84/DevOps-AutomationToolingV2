# Define the output file path relative to the script's location
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputFile = Join-Path $ScriptDirectory "UpdateHistory.txt"

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

    # Open a StreamWriter for writing the output to a file
    $StreamWriter = [System.IO.StreamWriter]::new($OutputFile, $false)

    # Iterate through the update history and display/write details
    foreach ($Update in $UpdateHistory) {
        $UpdateDetails = @"
Title: $($Update.Title)
Description: $($Update.Description)
Installation Date: $($Update.Date)
Status: $($Update.ResultCode)
----------------------------------
"@
        # Write details to console
        Write-Output $UpdateDetails

        # Write details to file
        $StreamWriter.WriteLine($UpdateDetails)
    }

    # Close the StreamWriter
    $StreamWriter.Close()
} else {
    $Message = "No update history found on this system."
    
    # Write message to console
    Write-Output $Message

    # Write message to file
    [System.IO.File]::WriteAllText($OutputFile, $Message)
}
