Add-Type -AssemblyName System.Windows.Forms

# Create the main GUI window
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "File Scanner"
$Form.Size = New-Object System.Drawing.Size(500, 400)
$Form.StartPosition = "CenterScreen"

# Create a dropdown for selecting the drive
$DriveLabel = New-Object System.Windows.Forms.Label
$DriveLabel.Text = "Select Drive:"
$DriveLabel.Location = New-Object System.Drawing.Point(20, 20)
$DriveLabel.AutoSize = $true
$Form.Controls.Add($DriveLabel)

$DriveDropdown = New-Object System.Windows.Forms.ComboBox
$DriveDropdown.Location = New-Object System.Drawing.Point(100, 15)
$DriveDropdown.Size = New-Object System.Drawing.Size(150, 30)
$DriveDropdown.DropDownStyle = "DropDownList"
$Form.Controls.Add($DriveDropdown)

# Populate the dropdown with available drives
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $DriveDropdown.Items.Add($_.Root)
}
$DriveDropdown.SelectedIndex = 0  # Select the first drive by default

# Create a button to start the scan
$ScanButton = New-Object System.Windows.Forms.Button
$ScanButton.Text = "Start Scan"
$ScanButton.Location = New-Object System.Drawing.Point(280, 12)
$ScanButton.Size = New-Object System.Drawing.Size(100, 30)
$Form.Controls.Add($ScanButton)

# Create a text area for verbose output
$OutputBox = New-Object System.Windows.Forms.TextBox
$OutputBox.Multiline = $true
$OutputBox.ScrollBars = "Vertical"
$OutputBox.Size = New-Object System.Drawing.Size(450, 250)
$OutputBox.Location = New-Object System.Drawing.Point(20, 60)
$OutputBox.ReadOnly = $true
$Form.Controls.Add($OutputBox)

# Create a progress bar
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(20, 320)
$ProgressBar.Size = New-Object System.Drawing.Size(450, 20)
$ProgressBar.Style = "Marquee"
$ProgressBar.Visible = $false
$Form.Controls.Add($ProgressBar)

# Function to log messages to the output box
function Log-Message {
    param ($Message)
    $OutputBox.AppendText("$Message`r`n")
    $OutputBox.SelectionStart = $OutputBox.Text.Length
    $OutputBox.ScrollToCaret()
}

# Function to start the file scan
$ScanButton.Add_Click({
    $SelectedDrive = $DriveDropdown.SelectedItem
    if (-not $SelectedDrive) {
        Log-Message "No drive selected!"
        return
    }

    $ComputerName = $env:COMPUTERNAME
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogFile = "${SelectedDrive}file_log_${ComputerName}_$timestamp.csv"

    Log-Message "Starting scan on $SelectedDrive..."
    $ProgressBar.Visible = $true
    $ScanButton.Enabled = $false

    try {
        Get-ChildItem -Path $SelectedDrive -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object FullName, Name, Extension, @{Name="Size_MB"; Expression={[math]::Round($_.Length / 1MB, 2)}} |
            Export-Csv -Path $LogFile -NoTypeInformation -Encoding UTF8
        
        Log-Message "File scan complete. Log saved to: $LogFile"
    }
    catch {
        Log-Message "Error during scan: $_"
    }
    finally {
        $ProgressBar.Visible = $false
        $ScanButton.Enabled = $true
    }
})

# Run the GUI
$Form.ShowDialog()
