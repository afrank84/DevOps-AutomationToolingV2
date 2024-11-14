Invoke-Command -ComputerName NameOfYourPcHere -ScriptBlock {
    $services = Get-Service | Where-Object { $_.DisplayName -like "GitHub*" }
    if ($services) {
        $services | ForEach-Object {
            "$($_.DisplayName) - Status: $($_.Status)"
        }
    } else {
        "No GitHub Actions runner services are running."
    }
}
