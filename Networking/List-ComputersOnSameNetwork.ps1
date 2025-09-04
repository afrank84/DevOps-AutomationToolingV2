Get-NetNeighbor -AddressFamily IPv4 |
  Where-Object {$_.State -ne 'Unreachable'} |
  ForEach-Object {
    $hostname = try { (Resolve-DnsName $_.IPAddress -ErrorAction Stop).NameHost.TrimEnd('.') } catch { $null }
    [pscustomobject]@{
      IPAddress      = $_.IPAddress
      Hostname       = $hostname
      MAC            = $_.LinkLayerAddress
      State          = $_.State
      InterfaceAlias = $_.InterfaceAlias
    }
  } | Sort-Object IPAddress | Format-Table -AutoSize
