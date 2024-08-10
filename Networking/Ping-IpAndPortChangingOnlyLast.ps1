function Test-PortRange {
    param (
        [string]$BaseIP,          # The base IP address, e.g., "10.0.0"
        [int]$Port,               # The port number to check
        [int]$Start,              # The start of the last octet range, e.g., 1
        [int]$End                 # The end of the last octet range, e.g., 254
    )

    # Validate inputs
    if (-not ($BaseIP -match '^\d{1,3}(\.\d{1,3}){2}$')) {
        Write-Host "Invalid IP address format. Please enter a valid base IP (e.g., 10.0.0)" -ForegroundColor Red
        return
    }
    if (-not ($Port -match '^\d+$') -or $Port -lt 1 -or $Port -gt 65535) {
        Write-Host "Invalid port number. Please enter a valid port (1-65535)" -ForegroundColor Red
        return
    }
    if ($Start -lt 0 -or $End -gt 255 -or $Start -gt $End) {
        Write-Host "Invalid octet range. Please enter valid numbers (0-255) with start <= end" -ForegroundColor Red
        return
    }

    # Create a script block to be run in parallel
    $scriptBlock = {
        param ($BaseIP, $Port, $i)

        $ip = "$($BaseIP).$($i)"
        try {
            $tcpConnection = New-Object System.Net.Sockets.TcpClient
            $tcpConnection.Connect($($ip), $($Port))
            if ($tcpConnection.Connected) {
                Write-Host "$($ip):$($Port) is reachable" -ForegroundColor Green
                $tcpConnection.Close()
            }
        } catch {
            Write-Host "$($ip):$($Port) is not reachable" -ForegroundColor Yellow
        }
    }

    # Use parallel processing to speed up the task
    $jobs = @()
    foreach ($i in $Start..$End) {
        $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $BaseIP, $Port, $i
    }

    # Wait for all jobs to complete
    $jobs | ForEach-Object { $_ | Wait-Job | Out-Null }

    # Retrieve and remove jobs
    $jobs | ForEach-Object { Receive-Job -Job $_; Remove-Job -Job $_ }
}

# Example usage
$BaseIP = Read-Host "Enter the base IP address (e.g., 10.0.0)"          # Example input: 10.0.0
$Port = [int](Read-Host "Enter the port number to check (e.g., 25565)") # Example input: 25565
$Start = [int](Read-Host "Enter the start of the last octet range (e.g., 1)")  # Example input: 1
$End = [int](Read-Host "Enter the end of the last octet range (e.g., 254)")    # Example input: 254


Test-PortRange -BaseIP $BaseIP -Port $Port -Start $Start -End $End
