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

    # Iterate through the update history and display details
    foreach ($Update in $UpdateHistory) {
        Write-Output "Title: $($Update.Title)"
        Write-Output "Description: $($Update.Description)"
        Write-Output "Installation Date: $($Update.Date)"
        Write-Output "Status: $($Update.ResultCode)"
        Write-Output "----------------------------------"
    }
} else {
    Write-Output "No update history found on this system."
}
