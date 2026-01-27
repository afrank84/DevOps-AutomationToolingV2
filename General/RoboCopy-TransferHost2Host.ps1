# Can simply copy ans paste the below directly into Powershell
& {
    $source = "\\HOSTNAME\FOLDER_NAME"
    $destinationRoot = "\\HOSTNAME\FOLDER_NAME"

    $folderName = Split-Path $source -Leaf
    $destination = Join-Path $destinationRoot $folderName

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = Join-Path $env:TEMP "robocopy-$timestamp.log"

    $opts = @(
        "/E",
        "/COPYALL",
        "/R:1",
        "/W:1",
        "/MT:16",
        "/ETA",
        "/NP",
        "/LOG:$logFile"
    )

    & robocopy "$source" "$destination" * $opts
    $rc = $LASTEXITCODE

    if ($rc -le 7) {
        Write-Host "Robocopy completed successfully (exit code $rc)"
        Write-Host "Log: $logFile"
    }
    else {
        throw "Robocopy failed with exit code $rc. See log: $logFile"
    }
}
