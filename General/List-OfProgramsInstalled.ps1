$OutputPath = [Environment]::GetFolderPath("Desktop") + "\InstalledPrograms.txt"
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
Select-Object DisplayName, InstallDate, Publisher |
Where-Object { $_.DisplayName -ne $null } |
Format-Table -AutoSize |
Out-File -FilePath $OutputPath

Write-Host "The list of installed programs has been saved to: $OutputPath"
