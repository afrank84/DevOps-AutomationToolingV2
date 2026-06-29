<# 
Windows-IR-Toolkit.ps1
Purpose: Offline Windows incident-response evidence collection with GUI buttons and callable functions.

Usage:
  1. Copy this file to the isolated machine.
  2. Right-click PowerShell and "Run as Administrator".
  3. Run:
       Set-ExecutionPolicy -Scope Process Bypass
       .\Windows-IR-Toolkit.ps1
  4. Use the GUI, or call functions manually from the PowerShell session.

Notes:
  - This script is collection-only. It does not remove malware or change persistence.
  - Some commands require Administrator rights.
  - Large recursive searches can take time.
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Continue"

# -----------------------------
# Global setup
# -----------------------------

$Script:StartedAt = Get-Date
$Script:HostName = $env:COMPUTERNAME
$Script:EvidenceRoot = Join-Path -Path $PSScriptRoot -ChildPath ("Evidence_{0}_{1}" -f $Script:HostName, (Get-Date -Format "yyyyMMdd_HHmmss"))
$Script:ErrorLog = Join-Path $Script:EvidenceRoot "Errors.log"
$Script:TranscriptLog = Join-Path $Script:EvidenceRoot "Transcript.log"

New-Item -ItemType Directory -Path $Script:EvidenceRoot -Force | Out-Null

try {
    Start-Transcript -Path $Script:TranscriptLog -Force | Out-Null
} catch {
    # Transcript can fail in some hosts. Continue.
}

function Write-IRLog {
    param(
        [string]$Message
    )
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $Script:ErrorLog -Value $line
}

function Get-OutputPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )
    return Join-Path $Script:EvidenceRoot $FileName
}

function Save-Text {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Collector
    )

    $path = Get-OutputPath $FileName
    try {
        "===== $FileName =====" | Out-File -FilePath $path -Encoding UTF8
        "Collected: $(Get-Date -Format o)" | Out-File -FilePath $path -Append -Encoding UTF8
        "Host: $env:COMPUTERNAME" | Out-File -FilePath $path -Append -Encoding UTF8
        "" | Out-File -FilePath $path -Append -Encoding UTF8

        & $Collector 2>&1 | Out-String -Width 4096 | Out-File -FilePath $path -Append -Encoding UTF8

        return $path
    } catch {
        Write-IRLog "FAILED $FileName : $($_.Exception.Message)"
        "ERROR: $($_.Exception.Message)" | Out-File -FilePath $path -Append -Encoding UTF8
        return $path
    }
}

function Save-CsvSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Collector
    )

    $path = Get-OutputPath $FileName
    try {
        & $Collector | Export-Csv -NoTypeInformation -Path $path -Encoding UTF8
        return $path
    } catch {
        Write-IRLog "FAILED $FileName : $($_.Exception.Message)"
        "ERROR: $($_.Exception.Message)" | Out-File -FilePath ($path + ".error.txt") -Encoding UTF8
        return $path
    }
}

function Test-IRAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Write-IRHeader {
    $admin = Test-IRAdmin
    Save-Text "00_Collection_Summary.txt" {
        "Evidence root: $Script:EvidenceRoot"
        "Started at: $Script:StartedAt"
        "Current time: $(Get-Date)"
        "Host: $env:COMPUTERNAME"
        "User: $env:USERNAME"
        "Administrator: $admin"
        "PowerShell version:"
        $PSVersionTable
    } | Out-Null
}

# -----------------------------
# 27 Collection Functions
# -----------------------------

function Get-IRSystemInformation {
    Save-Text "01_System_Information.txt" {
        hostname
        whoami
        Get-Date
        ""
        "===== Get-ComputerInfo ====="
        try { Get-ComputerInfo } catch { "Get-ComputerInfo failed: $($_.Exception.Message)" }
        ""
        "===== systeminfo ====="
        try { systeminfo } catch { "systeminfo failed: $($_.Exception.Message)" }
        ""
        "===== Environment ====="
        Get-ChildItem Env: | Sort-Object Name
    }
}

function Get-IRLocalUsers {
    Save-Text "02_Local_Users_and_Admins.txt" {
        "===== Get-LocalUser ====="
        try { Get-LocalUser | Format-List * } catch { "Get-LocalUser failed: $($_.Exception.Message)" }
        ""
        "===== Local Administrators ====="
        try { Get-LocalGroupMember Administrators | Format-List * } catch { "Get-LocalGroupMember failed: $($_.Exception.Message)" }
        ""
        "===== net user ====="
        cmd /c "net user"
        ""
        "===== net localgroup administrators ====="
        cmd /c "net localgroup administrators"
    }
}

function Get-IRUserProfiles {
    Save-Text "03_User_Profiles.txt" {
        Get-CimInstance Win32_UserProfile |
            Select-Object LocalPath, LastUseTime, Loaded, Special, SID |
            Sort-Object LastUseTime |
            Format-Table -AutoSize
    }
}

function Get-IRRecentlyCreatedFiles {
    param([int]$Days = 30)
    Save-CsvSafe "04_Recently_Created_Files_Last_${Days}_Days.csv" {
        Get-ChildItem C:\ -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer -and $_.CreationTime -gt (Get-Date).AddDays(-$Days) } |
            Select-Object CreationTime, LastWriteTime, Length, FullName |
            Sort-Object CreationTime
    }
}

function Find-IRPasswordCsvs {
    Save-CsvSafe "05_Password_CSV_Search.csv" {
        Get-ChildItem C:\ -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                -not $_.PSIsContainer -and
                ($_.Name -match "password|credential|login|chrome|edge|csv|vault|secret|export")
            } |
            Select-Object FullName, CreationTime, LastWriteTime, Length |
            Sort-Object CreationTime
    }
}

function Get-IRPowerShellHistory {
    Save-Text "06_PowerShell_History.txt" {
        $paths = Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\*" -ErrorAction SilentlyContinue
        if (-not $paths) { "No PSReadLine history files found." }
        foreach ($p in $paths) {
            "===== $($p.FullName) ====="
            "CreationTime: $($p.CreationTime)"
            "LastWriteTime: $($p.LastWriteTime)"
            ""
            try { Get-Content $p.FullName -ErrorAction Stop } catch { "Could not read: $($_.Exception.Message)" }
            ""
        }
    }
}

function Get-IRPowerShellEventLogs {
    Save-Text "07_PowerShell_Event_Logs.txt" {
        $logs = @(
            "Microsoft-Windows-PowerShell/Operational",
            "Windows PowerShell"
        )
        foreach ($log in $logs) {
            "===== $log ====="
            try {
                Get-WinEvent -LogName $log -MaxEvents 5000 -ErrorAction Stop |
                    Select-Object TimeCreated, Id, ProviderName, Message |
                    Format-List
            } catch {
                "Could not read $log : $($_.Exception.Message)"
            }
        }
    }
}

function Get-IRScheduledTasks {
    Save-Text "08_Scheduled_Tasks.txt" {
        try {
            Get-ScheduledTask |
                Sort-Object TaskPath, TaskName |
                Select-Object TaskName, TaskPath, State, Author, Description |
                Format-List
        } catch {
            "Get-ScheduledTask failed: $($_.Exception.Message)"
        }

        ""
        "===== schtasks /query /fo LIST /v ====="
        cmd /c "schtasks /query /fo LIST /v"
    }
}

function Get-IRServices {
    Save-Text "09_Services.txt" {
        "===== Get-Service ====="
        Get-Service | Sort-Object Status, DisplayName | Format-Table -AutoSize
        ""
        "===== Win32_Service with paths ====="
        Get-CimInstance Win32_Service |
            Select-Object Name, DisplayName, State, StartMode, StartName, PathName |
            Sort-Object Name |
            Format-List
    }
}

function Get-IRStartupEntries {
    Save-Text "10_Startup_Entries.txt" {
        "===== Win32_StartupCommand ====="
        Get-CimInstance Win32_StartupCommand |
            Select-Object Name, Command, Location, User |
            Format-List

        ""
        "===== Startup folders ====="
        $startupPaths = @(
            "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
            "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
        )
        foreach ($sp in $startupPaths) {
            "----- $sp -----"
            Get-ChildItem $sp -Force -ErrorAction SilentlyContinue | Select-Object FullName, CreationTime, LastWriteTime, Length
        }
    }
}

function Get-IRRunRegistryKeys {
    Save-Text "11_Run_Registry_Keys.txt" {
        $keys = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
        )
        foreach ($key in $keys) {
            "===== $key ====="
            try { Get-ItemProperty $key -ErrorAction Stop | Format-List } catch { "Not found or unreadable: $($_.Exception.Message)" }
        }
    }
}

function Get-IRInstalledPrograms {
    Save-Text "12_Installed_Programs.txt" {
        "===== Get-Package ====="
        try { Get-Package | Sort-Object Name | Format-Table -AutoSize } catch { "Get-Package failed: $($_.Exception.Message)" }

        ""
        "===== Registry uninstall entries ====="
        $uninstallKeys = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($key in $uninstallKeys) {
            Get-ItemProperty $key -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, UninstallString |
                Sort-Object DisplayName |
                Format-Table -AutoSize
        }
    }
}

function Get-IRRecentlyInstalledPrograms {
    Save-CsvSafe "13_Recently_Installed_Programs.csv" {
        $uninstallKeys = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($key in $uninstallKeys) {
            Get-ItemProperty $key -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, UninstallString, PSPath
        }
    }
}

function Get-IRAnyDeskArtifacts {
    Save-Text "14_AnyDesk_Artifacts.txt" {
        $paths = @(
            "C:\ProgramData\AnyDesk",
            "$env:APPDATA\AnyDesk",
            "C:\Users\*\AppData\Roaming\AnyDesk",
            "C:\Program Files (x86)\AnyDesk",
            "C:\Program Files\AnyDesk"
        )

        foreach ($path in $paths) {
            "===== $path ====="
            Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
                Select-Object FullName, CreationTime, LastWriteTime, Length |
                Sort-Object LastWriteTime |
                Format-Table -AutoSize
            ""
        }

        "===== AnyDesk services/process hints ====="
        Get-CimInstance Win32_Service | Where-Object { $_.Name -match "AnyDesk" -or $_.DisplayName -match "AnyDesk" } | Format-List *
    }
}

function Get-IRRustDeskArtifacts {
    Save-Text "15_RustDesk_Artifacts.txt" {
        $paths = @(
            "$env:APPDATA\RustDesk",
            "C:\Users\*\AppData\Roaming\RustDesk",
            "C:\ProgramData\RustDesk",
            "C:\Program Files\RustDesk",
            "C:\Program Files (x86)\RustDesk"
        )

        foreach ($path in $paths) {
            "===== $path ====="
            Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
                Select-Object FullName, CreationTime, LastWriteTime, Length |
                Sort-Object LastWriteTime |
                Format-Table -AutoSize
            ""
        }

        "===== RustDesk services/process hints ====="
        Get-CimInstance Win32_Service | Where-Object { $_.Name -match "RustDesk" -or $_.DisplayName -match "RustDesk" } | Format-List *
    }
}

function Get-IRRdpLogins {
    Save-Text "16_RDP_Logins_Event_4624.txt" {
        "Logon Type 10 = RemoteInteractive/RDP"
        "Logon Type 7 = Unlock"
        "Logon Type 3 = Network"
        ""
        try {
            Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 5000 |
                Where-Object { $_.Message -match "Logon Type:\s+10|Logon Type:\s+7|Logon Type:\s+3" } |
                Select-Object TimeCreated, Id, ProviderName, Message |
                Format-List
        } catch {
            "Could not read Security log: $($_.Exception.Message)"
        }

        ""
        "===== TerminalServices RemoteConnectionManager 1149 ====="
        try {
            Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" -MaxEvents 5000 |
                Select-Object TimeCreated, Id, ProviderName, Message |
                Format-List
        } catch {
            "Could not read TerminalServices log: $($_.Exception.Message)"
        }
    }
}

function Get-IRFailedLogins {
    Save-Text "17_Failed_Logins_Event_4625.txt" {
        try {
            Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 5000 |
                Select-Object TimeCreated, Id, ProviderName, Message |
                Format-List
        } catch {
            "Could not read failed logins: $($_.Exception.Message)"
        }
    }
}

function Get-IRServiceDetails {
    Save-CsvSafe "18_Service_Details.csv" {
        Get-CimInstance Win32_Service |
            Select-Object Name, DisplayName, State, StartMode, StartName, PathName, ProcessId |
            Sort-Object Name
    }
}

function Get-IRNetworkShares {
    Save-Text "19_Network_Shares.txt" {
        "===== Get-SmbShare ====="
        try { Get-SmbShare | Format-List * } catch { "Get-SmbShare failed: $($_.Exception.Message)" }

        ""
        "===== net share ====="
        cmd /c "net share"

        ""
        "===== net use ====="
        cmd /c "net use"
    }
}

function Get-IRFirewallRules {
    Save-CsvSafe "20_Enabled_Firewall_Rules.csv" {
        Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue |
            Select-Object DisplayName, Name, Direction, Action, Enabled, Profile, Program, Service, Description |
            Sort-Object DisplayName
    }
}

function Get-IRDefenderHistory {
    Save-Text "21_Defender_History.txt" {
        "===== Defender Status ====="
        try { Get-MpComputerStatus | Format-List * } catch { "Get-MpComputerStatus failed: $($_.Exception.Message)" }

        ""
        "===== Threats ====="
        try { Get-MpThreat | Format-List * } catch { "Get-MpThreat failed: $($_.Exception.Message)" }

        ""
        "===== Threat Detections ====="
        try { Get-MpThreatDetection | Format-List * } catch { "Get-MpThreatDetection failed: $($_.Exception.Message)" }

        ""
        "===== Defender Operational Log ====="
        try {
            Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 3000 |
                Select-Object TimeCreated, Id, ProviderName, Message |
                Format-List
        } catch {
            "Could not read Defender Operational log: $($_.Exception.Message)"
        }
    }
}

function Get-IRRecentExecutables {
    param([int]$Days = 30)
    Save-CsvSafe "22_Recent_EXEs_Last_${Days}_Days.csv" {
        Get-ChildItem C:\ -Include *.exe,*.dll,*.ps1,*.bat,*.cmd,*.vbs,*.js,*.msi -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer -and $_.CreationTime -gt (Get-Date).AddDays(-$Days) } |
            Select-Object CreationTime, LastWriteTime, Length, FullName |
            Sort-Object CreationTime
    }
}

function Get-IRPrefetch {
    Save-CsvSafe "23_Prefetch.csv" {
        Get-ChildItem C:\Windows\Prefetch -ErrorAction SilentlyContinue |
            Select-Object LastWriteTime, CreationTime, Name, Length, FullName |
            Sort-Object LastWriteTime
    }
}

function Get-IRUsbDevices {
    Save-Text "24_USB_Devices.txt" {
        "===== Current USB PnP devices ====="
        try {
            Get-PnpDevice | Where-Object { $_.Class -eq "USB" -or $_.InstanceId -match "USB" } | Format-Table -AutoSize
        } catch {
            "Get-PnpDevice failed: $($_.Exception.Message)"
        }

        ""
        "===== USBSTOR Registry ====="
        try {
            Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR" -Recurse -ErrorAction SilentlyContinue |
                Select-Object Name, Property |
                Format-List
        } catch {
            "USBSTOR read failed: $($_.Exception.Message)"
        }
    }
}

function Find-IREncodedPowerShell {
    Save-Text "25_Encoded_PowerShell_Search.txt" {
        $patterns = @(
            "EncodedCommand",
            "-enc ",
            "-encodedcommand",
            "FromBase64String",
            "Invoke-Expression",
            "IEX",
            "DownloadString",
            "DownloadFile",
            "Net.WebClient",
            "System.Text.Encoding"
        )

        $files = Get-ChildItem C:\ -Recurse -Include *.ps1,*.psm1,*.bat,*.cmd,*.txt,*.xml,*.vbs,*.js,*.log -Force -ErrorAction SilentlyContinue
        foreach ($pattern in $patterns) {
            "===== Pattern: $pattern ====="
            try {
                $files | Select-String -Pattern $pattern -ErrorAction SilentlyContinue |
                    Select-Object Path, LineNumber, Line |
                    Format-List
            } catch {
                "Search failed for $pattern : $($_.Exception.Message)"
            }
        }
    }
}

function Find-IRCredentialDumpingIndicators {
    Save-Text "26_Credential_Dumping_Search.txt" {
        $patterns = @(
            "mimikatz",
            "sekurlsa",
            "logonpasswords",
            "lsass",
            "procdump",
            "comsvcs.dll",
            "MiniDump",
            "vault",
            "credential",
            "browserpass",
            "lazagne",
            "chromepass",
            "webbrowserpassview",
            "passwords.csv",
            "Export-Csv"
        )

        "===== Filename matches ====="
        Get-ChildItem C:\ -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "mimikatz|lazagne|chromepass|browserpass|procdump|lsass|password|credential|vault" } |
            Select-Object FullName, CreationTime, LastWriteTime, Length |
            Sort-Object CreationTime |
            Format-Table -AutoSize

        ""
        "===== Text content matches ====="
        $files = Get-ChildItem C:\ -Recurse -Include *.ps1,*.psm1,*.bat,*.cmd,*.txt,*.xml,*.vbs,*.js,*.log,*.csv -Force -ErrorAction SilentlyContinue
        foreach ($pattern in $patterns) {
            "===== Pattern: $pattern ====="
            try {
                $files | Select-String -Pattern $pattern -ErrorAction SilentlyContinue |
                    Select-Object Path, LineNumber, Line |
                    Format-List
            } catch {
                "Search failed for $pattern : $($_.Exception.Message)"
            }
        }
    }
}

function Get-IRCsvTimeline {
    param(
        [string]$CsvPath = "",
        [int]$Minutes = 30
    )

    Save-CsvSafe "27_Timeline_Around_Password_CSV.csv" {
        if ([string]::IsNullOrWhiteSpace($CsvPath)) {
            $candidate = Get-ChildItem C:\ -Filter "ICW4passwords.csv" -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($candidate) {
                $CsvPath = $candidate.FullName
            }
        }

        if ([string]::IsNullOrWhiteSpace($CsvPath) -or -not (Test-Path $CsvPath)) {
            [PSCustomObject]@{
                Note = "ICW4passwords.csv not found automatically. Re-run Get-IRCsvTimeline -CsvPath 'C:\path\ICW4passwords.csv'"
                CsvPath = $CsvPath
                Minutes = $Minutes
            }
            return
        }

        $csv = Get-Item $CsvPath
        $start = $csv.CreationTime.AddMinutes(-$Minutes)
        $end = $csv.CreationTime.AddMinutes($Minutes)

        Get-ChildItem C:\ -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                -not $_.PSIsContainer -and
                (
                    ($_.CreationTime -ge $start -and $_.CreationTime -le $end) -or
                    ($_.LastWriteTime -ge $start -and $_.LastWriteTime -le $end)
                )
            } |
            Select-Object CreationTime, LastWriteTime, Length, FullName |
            Sort-Object CreationTime
    }
}

# -----------------------------
# Extra helper functions
# -----------------------------

function Export-IREventLogsEvtx {
    Save-Text "28_EVTX_Export_Status.txt" {
        $evtxDir = Join-Path $Script:EvidenceRoot "EVTX"
        New-Item -ItemType Directory -Path $evtxDir -Force | Out-Null

        $logs = @(
            "Security",
            "System",
            "Application",
            "Microsoft-Windows-PowerShell/Operational",
            "Windows PowerShell",
            "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational",
            "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
            "Microsoft-Windows-Windows Defender/Operational"
        )

        foreach ($log in $logs) {
            $safe = $log.Replace("/", "_").Replace("\", "_")
            $dest = Join-Path $evtxDir "$safe.evtx"
            "Exporting $log to $dest"
            try {
                wevtutil epl "$log" "$dest"
            } catch {
                "Failed: $($_.Exception.Message)"
            }
        }
    }
}

function New-IRFileHashes {
    Save-CsvSafe "99_Output_File_Hashes_SHA256.csv" {
        Get-ChildItem $Script:EvidenceRoot -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notlike "*99_Output_File_Hashes_SHA256.csv" } |
            Get-FileHash -Algorithm SHA256 |
            Select-Object Algorithm, Hash, Path
    }
}

function Invoke-IRRunAll {
    Write-IRHeader
    Get-IRSystemInformation
    Get-IRLocalUsers
    Get-IRUserProfiles
    Get-IRRecentlyCreatedFiles
    Find-IRPasswordCsvs
    Get-IRPowerShellHistory
    Get-IRPowerShellEventLogs
    Get-IRScheduledTasks
    Get-IRServices
    Get-IRStartupEntries
    Get-IRRunRegistryKeys
    Get-IRInstalledPrograms
    Get-IRRecentlyInstalledPrograms
    Get-IRAnyDeskArtifacts
    Get-IRRustDeskArtifacts
    Get-IRRdpLogins
    Get-IRFailedLogins
    Get-IRServiceDetails
    Get-IRNetworkShares
    Get-IRFirewallRules
    Get-IRDefenderHistory
    Get-IRRecentExecutables
    Get-IRPrefetch
    Get-IRUsbDevices
    Find-IREncodedPowerShell
    Find-IRCredentialDumpingIndicators
    Get-IRCsvTimeline
    Export-IREventLogsEvtx
    New-IRFileHashes
    return $Script:EvidenceRoot
}

# -----------------------------
# GUI
# -----------------------------

function Show-IRGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Windows IR Toolkit - Evidence Collector"
    $form.Size = New-Object System.Drawing.Size(900, 720)
    $form.StartPosition = "CenterScreen"

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Windows IR Toolkit - Offline Evidence Collection"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(15, 12)
    $form.Controls.Add($title)

    $outputLabel = New-Object System.Windows.Forms.Label
    $outputLabel.Text = "Output: $Script:EvidenceRoot"
    $outputLabel.AutoSize = $true
    $outputLabel.Location = New-Object System.Drawing.Point(15, 42)
    $form.Controls.Add($outputLabel)

    $statusBox = New-Object System.Windows.Forms.TextBox
    $statusBox.Multiline = $true
    $statusBox.ScrollBars = "Vertical"
    $statusBox.ReadOnly = $true
    $statusBox.Location = New-Object System.Drawing.Point(15, 540)
    $statusBox.Size = New-Object System.Drawing.Size(850, 120)
    $form.Controls.Add($statusBox)

    function Add-Status {
        param([string]$Text)
        $statusBox.AppendText(("[{0}] {1}`r`n" -f (Get-Date -Format "HH:mm:ss"), $Text))
        $statusBox.SelectionStart = $statusBox.Text.Length
        $statusBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    $buttons = @(
        @("Run All", { Invoke-IRRunAll }),
        @("01 System Info", { Get-IRSystemInformation }),
        @("02 Local Users", { Get-IRLocalUsers }),
        @("03 User Profiles", { Get-IRUserProfiles }),
        @("04 Recent Files", { Get-IRRecentlyCreatedFiles }),
        @("05 Password CSV Search", { Find-IRPasswordCsvs }),
        @("06 PS History", { Get-IRPowerShellHistory }),
        @("07 PS Event Logs", { Get-IRPowerShellEventLogs }),
        @("08 Scheduled Tasks", { Get-IRScheduledTasks }),
        @("09 Services", { Get-IRServices }),
        @("10 Startup Entries", { Get-IRStartupEntries }),
        @("11 Run Registry", { Get-IRRunRegistryKeys }),
        @("12 Installed Programs", { Get-IRInstalledPrograms }),
        @("13 Recent Installs", { Get-IRRecentlyInstalledPrograms }),
        @("14 AnyDesk", { Get-IRAnyDeskArtifacts }),
        @("15 RustDesk", { Get-IRRustDeskArtifacts }),
        @("16 RDP Logins", { Get-IRRdpLogins }),
        @("17 Failed Logins", { Get-IRFailedLogins }),
        @("18 Service Details", { Get-IRServiceDetails }),
        @("19 Network Shares", { Get-IRNetworkShares }),
        @("20 Firewall Rules", { Get-IRFirewallRules }),
        @("21 Defender", { Get-IRDefenderHistory }),
        @("22 Recent EXEs", { Get-IRRecentExecutables }),
        @("23 Prefetch", { Get-IRPrefetch }),
        @("24 USB Devices", { Get-IRUsbDevices }),
        @("25 Encoded PS", { Find-IREncodedPowerShell }),
        @("26 Cred Dump Search", { Find-IRCredentialDumpingIndicators }),
        @("27 CSV Timeline", { Get-IRCsvTimeline }),
        @("Export EVTX Logs", { Export-IREventLogsEvtx }),
        @("Hash Outputs", { New-IRFileHashes }),
        @("Open Output Folder", { Start-Process explorer.exe $Script:EvidenceRoot })
    )

    $x = 15
    $y = 75
    $w = 200
    $h = 32
    $gapX = 215
    $gapY = 38
    $col = 0
    $row = 0

    foreach ($b in $buttons) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $b[0]
        $button.Size = New-Object System.Drawing.Size($w, $h)
        $button.Location = New-Object System.Drawing.Point(($x + ($col * $gapX)), ($y + ($row * $gapY)))

        $action = $b[1]
        $name = $b[0]
        $button.Add_Click({
            try {
                Add-Status "Started: $name"
                $result = & $action
                Add-Status "Finished: $name"
                if ($result) { Add-Status "Output: $result" }
            } catch {
                Add-Status "ERROR in $name : $($_.Exception.Message)"
                Write-IRLog "GUI ERROR $name : $($_.Exception.Message)"
            }
        }.GetNewClosure())

        $form.Controls.Add($button)

        $col++
        if ($col -ge 4) {
            $col = 0
            $row++
        }
    }

    $adminNotice = New-Object System.Windows.Forms.Label
    if (Test-IRAdmin) {
        $adminNotice.Text = "Running as Administrator: Yes"
    } else {
        $adminNotice.Text = "Running as Administrator: No - some logs/artifacts may be missing"
    }
    $adminNotice.AutoSize = $true
    $adminNotice.Location = New-Object System.Drawing.Point(15, 500)
    $form.Controls.Add($adminNotice)

    Add-Status "Ready. Evidence folder created."
    [void]$form.ShowDialog()
}

# -----------------------------
# Script entry
# -----------------------------

Write-IRHeader

if ($Host.Name -match "ConsoleHost|Windows PowerShell ISE Host|Visual Studio Code Host") {
    Show-IRGui
} else {
    "GUI may not be available in this host. You can manually call Invoke-IRRunAll or individual Get-IR* functions."
}

try {
    Stop-Transcript | Out-Null
} catch {
    # ignore
}
