# Script to gather and display host computer information

# Get host computer name
$computerName = $env:COMPUTERNAME

# Output computer information
Write-Host "Computer Name: $computerName"

# Check PowerShell version and use appropriate cmdlet
if ($PSVersionTable.PSVersion.Major -lt 7) {
    try {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
        $physicalMemory = Get-WmiObject Win32_PhysicalMemory | Measure-Object Capacity -Sum | Select-Object @{Name="TotalPhysicalMemory";Expression={[Math]::Round($_.Sum / 1GB, 2)}}
    } catch {
        Write-Host "Error: $_"
    }
} else {
    try {
        $disk = Get-CimInstance CIM_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
        $physicalMemory = Get-CimInstance CIM_PhysicalMemory | Measure-Object Capacity -Sum | Select-Object @{Name="TotalPhysicalMemory";Expression={[Math]::Round($_.Sum / 1GB, 2)}}
    } catch {
        Write-Host "Error: $_"
    }
}

# Calculate disk and memory information if queries were successful
if ($disk -and $physicalMemory) {
    $totalDiskSpace = [Math]::Round($disk.Size / 1GB, 2)
    $availableDiskSpace = [Math]::Round($disk.FreeSpace / 1GB, 2)
    $totalPhysicalMemory = $physicalMemory.TotalPhysicalMemory

    # Check if computer is a physical machine or a virtual machine
    try {
        $systemManufacturer = (Get-CimInstance CIM_ComputerSystem).Manufacturer
        $systemModel = (Get-CimInstance CIM_ComputerSystem).Model
        if ($systemManufacturer -eq "Microsoft Corporation" -and $systemModel -like "*Virtual*") {
            $computerType = "Virtual Machine"
        } else {
            $computerType = "Physical Machine"
        }
    } catch {
        Write-Host "Error: $_"
        $computerType = "Unknown"
    }

    # Output results
    Write-Host "Total Disk Space: $totalDiskSpace GB"
    Write-Host "Available Disk Space: $availableDiskSpace GB"
    Write-Host "Total Physical Memory: $totalPhysicalMemory GB"
    Write-Host "Computer Type: $computerType"
} else {
    Write-Host "Failed to retrieve disk or memory information."
}

Write-Host "---------------------"
