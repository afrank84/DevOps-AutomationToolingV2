function Monitor-NetworkDevices {
    param (
        [string]$logFilePath = "C:\Path\To\Your\Log\File.txt"
    )

    # Get a list of network devices (network adapters)
    $networkDevices = Get-NetAdapter

    # Create a timestamp for the log
    $logTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Initialize a flag to track if any device is down
    $anyDeviceDown = $false

    # Initialize an array to hold log messages
    $logMessages = @()

    # Loop through each network device
    foreach ($device in $networkDevices) {
        $deviceName = $device.Name
        $deviceStatus = $device.Status

        # Check if the device status is 'Disconnected'
        if ($deviceStatus -eq 'Disconnected') {
            $logMessage = "$logTimestamp - Network device $deviceName is down."
            $anyDeviceDown = $true
        } else {
            $logMessage = "$logTimestamp - Network device $deviceName is already up and running."
        }

        # Add the log message to the array
        $logMessages += $logMessage
    }

    # Check if any device is down
    if ($anyDeviceDown) {
        # Disable all network adapters
        Disable-NetAdapter -Name *

        # Log the action
        $logMessage = "$logTimestamp - All network devices have been disabled due to at least one device being down."
        $logMessages += $logMessage

        # Enable all network adapters
        Enable-NetAdapter -Name *

        # Log the action
        $logMessage = "$logTimestamp - All network devices have been re-enabled."
        $logMessages += $logMessage
    }

    # Write log messages to the log file
    $logMessages | Out-File -FilePath $logFilePath -Append

    # Display log messages in the console
    $logMessages
}

# Example usage:
Monitor-NetworkDevices -logFilePath "C:\Path\To\Your\Log\File.txt"
