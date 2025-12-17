Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Delayed Command Typer"
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"

# --- Command box ---
$cmdLabel = New-Object System.Windows.Forms.Label
$cmdLabel.Text = "Command / Script:"
$cmdLabel.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($cmdLabel)

$cmdBox = New-Object System.Windows.Forms.TextBox
$cmdBox.Multiline = $true
$cmdBox.ScrollBars = "Vertical"
$cmdBox.Size = New-Object System.Drawing.Size(860, 350)
$cmdBox.Location = New-Object System.Drawing.Point(10, 30)
$form.Controls.Add($cmdBox)

# --- Delay ---
$delayLabel = New-Object System.Windows.Forms.Label
$delayLabel.Text = "Start delay (seconds):"
$delayLabel.Location = New-Object System.Drawing.Point(10, 400)
$form.Controls.Add($delayLabel)

$delayBox = New-Object System.Windows.Forms.TextBox
$delayBox.Text = "5"
$delayBox.Size = New-Object System.Drawing.Size(60, 20)
$delayBox.Location = New-Object System.Drawing.Point(160, 397)
$form.Controls.Add($delayBox)

# --- Key delay ---
$keyDelayLabel = New-Object System.Windows.Forms.Label
$keyDelayLabel.Text = "Key delay (ms):"
$keyDelayLabel.Location = New-Object System.Drawing.Point(250, 400)
$form.Controls.Add($keyDelayLabel)

$keyDelayBox = New-Object System.Windows.Forms.TextBox
$keyDelayBox.Text = "40"
$keyDelayBox.Size = New-Object System.Drawing.Size(60, 20)
$keyDelayBox.Location = New-Object System.Drawing.Point(350, 397)
$form.Controls.Add($keyDelayBox)

# --- Status ---
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Idle"
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(10, 440)
$form.Controls.Add($statusLabel)

# --- Button ---
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Typing"
$startButton.Size = New-Object System.Drawing.Size(120, 30)
$startButton.Location = New-Object System.Drawing.Point(750, 390)
$form.Controls.Add($startButton)

# --- Action ---
$startButton.Add_Click({
    $text = $cmdBox.Text -replace "`r", ""
    $delay = [int]$delayBox.Text
    $keyDelay = [int]$keyDelayBox.Text

    $statusLabel.Text = "Waiting $delay seconds..."
    $form.Refresh()

    Start-Sleep -Seconds $delay

    $statusLabel.Text = "Typing..."
    $form.Refresh()

    foreach ($line in $text -split "`n") {
        foreach ($char in $line.ToCharArray()) {
            [System.Windows.Forms.SendKeys]::SendWait($char)
            Start-Sleep -Milliseconds $keyDelay
        }
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Start-Sleep -Milliseconds ($keyDelay * 2)
    }

    $statusLabel.Text = "Done"
})

# --- Run ---
[void]$form.ShowDialog()
