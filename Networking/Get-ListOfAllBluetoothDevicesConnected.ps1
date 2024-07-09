# Get all connected PnP devices
$devices = Get-PnpDevice -Class Bluetooth

# Filter out only connected devices
$connectedDevices = $devices | Where-Object { $_.Status -eq 'OK' }

# Display the connected Bluetooth devices
if ($connectedDevices) {
    Write-Output "Connected Bluetooth Devices:"
    $connectedDevices | ForEach-Object {
        Write-Output "---------------------------------"
        Write-Output "Device ID: $($_.DeviceID)"
        Write-Output "Name: $($_.FriendlyName)"
        Write-Output "Status: $($_.Status)"
    }
} else {
    Write-Output "No connected Bluetooth devices found."
}
