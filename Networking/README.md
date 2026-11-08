# Network inspection and recovery

These are independent scripts. Configure local copies and run only on networks
and machines you administer. Descriptions come from source review, not execution.

## [Ping-IpAndPortChangingOnlyLast.ps1](Ping-IpAndPortChangingOnlyLast.ps1)

Prompts for a three-octet base address, TCP port, and last-octet start/end range.
It starts one PowerShell background job per address, uses `TcpClient.Connect`,
waits for all jobs, and prints reachable/unreachable results. This is a TCP
connection test, not an ICMP ping. Run with PowerShell:

```powershell
.\Networking\Ping-IpAndPortChangingOnlyLast.ps1
```

The port must be 1–65535 and the range 0–255. The base-address regex checks shape
but does not validate each octet's numerical range. There is no explicit connect
timeout or concurrency limit beyond the requested range; large ranges create
many processes and can take time. No output file is written.

## [List-ComputersOnSameNetwork.ps1](List-ComputersOnSameNetwork.ps1)

Queries Windows `Get-NetNeighbor` for IPv4 entries not marked Unreachable,
attempts reverse DNS for each, then prints IP, hostname, MAC, state, and interface.
Run the script in Windows PowerShell with the NetTCPIP module available. It uses
the local neighbor cache, so it does not discover every computer or actively
scan the subnet. Failed name lookups leave a blank hostname.

## [Get-ListOfAllBluetoothDevicesConnected.ps1](Get-ListOfAllBluetoothDevicesConnected.ps1)

Uses Windows `Get-PnpDevice -Class Bluetooth`, filters for `Status -eq 'OK'`, and
prints IDs, friendly names, and status. Run in Windows PowerShell with PnpDevice
available. An OK PnP status does not by itself prove an active Bluetooth session;
this reports device status rather than radio connection telemetry.

## [Monitor-NetworkCardEnableIfDisabled.ps1](Monitor-NetworkCardEnableIfDisabled.ps1)

Reads Windows adapter status once. If **any** adapter is Disconnected, it invokes
`Disable-NetAdapter -Name *` and `Enable-NetAdapter -Name *`, then appends messages
to a configured log. It does not continuously monitor and does not merely enable
one disabled adapter.

Set the final `Monitor-NetworkDevices -logFilePath ...` call in a local copy to
an existing writable log directory, then run the file with administrator rights.
Expect a network interruption affecting all adapters and potentially your remote
session. Cmdlet confirmations can appear. It has no rollback if re-enable fails.

## [Get-LinuxWifPasswordHistory.sh](Get-LinuxWifPasswordHistory.sh)

Reads files under `/etc/NetworkManager/system-connections/` and uses GNU
`grep -P` to print `ssid=` and `psk=` values. It requires Bash, GNU grep, and
permission to read those protected profiles. Invoke with Bash under an account
authorized to inspect the machine's saved connections.

It shows saved plaintext PSKs present in current profiles, not a historical log
or passwords held only in a keyring. Passwords are printed to stdout: do not
capture the output in shared logs. The script does not change profiles.
