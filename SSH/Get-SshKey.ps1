# Generate SSH key pair
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
ssh-keygen -t rsa -b 4096 -C "GITHUB_EMAIL" -f $sshKeyPath

# Output public key
Write-Host "Your public SSH key is:"
Get-Content "$($sshKeyPath).pub"
