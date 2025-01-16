# Define the output directory for log collection
$OutputDirectory = "C:\ForensicLogs\ActiveDirectory"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory
}

# Function to collect Active Directory logon events
function Collect-ADLogonEvents {
    $LogonEventsFile = "$OutputDirectory\ActiveDirectoryLogons.csv"
    Write-Output "Collecting Active Directory logon events..."

    # Filter for event ID 4624 (successful logons) in the Security log
    $LogonEvents = Get-WinEvent -LogName Security -FilterHashtable @{Id=4624} -ErrorAction SilentlyContinue | ForEach-Object {
        $EventData = $_ | Select-Object -ExpandProperty Properties
        [PSCustomObject]@{
            TimeCreated = $_.TimeCreated  # The time the event was created
            UserName    = $EventData[5].Value  # Account name of the logged-in user
            LogonType   = $EventData[8].Value  # Type of logon (e.g., interactive, remote)
            SourceIP    = $EventData[18].Value # Source IP address of the connection
        }
    }

    # Export the collected logon data to a CSV file
    $LogonEvents | Export-Csv -Path $LogonEventsFile -NoTypeInformation -Encoding UTF8

    Write-Output "Active Directory logon events saved to $LogonEventsFile."
}

# Call the function to collect AD logon events
Collect-ADLogonEvents

Write-Output "Active Directory logon event collection completed. Logs saved to $OutputDirectory."
