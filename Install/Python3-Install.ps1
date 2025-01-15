# Check if Python is installed and get the version
$pythonVersion = python --version 2>$null

if ($pythonVersion) {
    Write-Output "Python is already installed: $pythonVersion"
} else {
    Write-Output "Python is not installed. Proceeding with installation."

    # Define the URL for the Python installer
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"
    $installerPath = "python-installer.exe"

    # Download the Python installer
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath
    Write-Output "Downloaded Python installer."

    # Run the installer
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    Write-Output "Python installer has completed."

    # Verify installation
    $pythonVersion = python --version 2>$null
    if ($pythonVersion) {
        Write-Output "Python installed successfully: $pythonVersion"
    } else {
        Write-Output "Python installation failed."
    }

    # Clean up the installer
    Remove-Item $installerPath
    Write-Output "Cleaned up the installer."
}
