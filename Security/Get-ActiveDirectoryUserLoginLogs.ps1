# Function to detect the USB flash drive
function Get-USBDrive {
    # Get the list of drives and filter for removable drives
    $USBDrive = Get-PSDrive -PSProvider FileSystem | Where-Object {
        ($_.Root -match '^[A-Z]:\\$') -and
        ([System.IO.DriveInfo]::GetDrives() | Where-Object {
            $_.Name -eq $_.Root -and $_.DriveType -eq 'Removable'
        })
    }
    return $USBDrive
}

# Get the USB drive and define the output directory
$USBDrive = Get-USBDrive
if (-not $USBDrive) {
    Write-Output "No USB flash drive detected. Please insert a USB drive and try again."
    exit
}

$OutputDirectory = Join-Path $USBDrive.Root "ForensicLogs\ActiveDirectory"

# Create the output directory on the USB drive if it doesn't exist
if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
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

    # Export the collected logon data to a CSV file on the USB drive
    $LogonEvents | Export-Csv -Path $LogonEventsFile -NoTypeInformation -Encoding UTF8

    Write-Output "Active Directory logon events saved to $LogonEventsFile."
}

# Call the function to collect AD logon events
Collect-ADLogonEvents

Write-Output "Active Directory logon event collection completed. Logs saved to $OutputDirectory."
