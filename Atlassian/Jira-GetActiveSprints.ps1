[string]$username = Read-Host -Prompt "Enter Jira Admin User"
$securedValue = Read-Host -AsSecureString -Prompt "Enter User password"
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$userPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

[string]$plainTextCredential = "$userName`:$userPassword"
$sEncodedString = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($plainTextCredential))
$Headers = @{ Authorization = "Basic $sEncodedString" }

$activeSprintQuery = 'https://ENTER_YOUR_DOMAIN/rest/agile/1.0/board/21/sprint?state=active'

$res = Invoke-WebRequest -Headers $Headers -Uri $activeSprintQuery -UseBasicParsing
$body = $res.Content | ConvertFrom-Json
[int]$sprint = $body.values[0].id

$query = "https://ENTER_YOUR_DOMAIN_HERE/rest/agile/1.0/sprint/$sprint/issue"


$issues = New-Object System.Collections.Generic.List[System.Object]

$url = $query
While (![string]::IsNullOrWhiteSpace($url)) {
    $res = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers $Headers
    $url = $null

    if ($res.StatusCode -eq 200) {
        $body = $res.Content | ConvertFrom-Json

        foreach($issue in $body.issues){
            $issues.Add($issue)
        }

        if($issues.Count -lt $body.total){
            $url = $query + "?startAt=$($issues.Count)"
        }    
    }
}

$issues | ConvertTo-Json -Depth 10 | Out-File -FilePath $PSScriptRoot\issues.json
