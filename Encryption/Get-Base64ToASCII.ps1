function Decode-Base64Password {
    param (
        [string]$base64Password
    )

    # Validate Base64 string
    if ($base64Password -match '^[a-zA-Z0-9\+/]*={0,2}$') {
        # Decode from base64 to binary
        try {
            $bytes = [System.Convert]::FromBase64String($base64Password)
        } catch {
            Write-Host "Error: The input is not a valid Base-64 string."
            return
        }

        if ($bytes -ne $null) {
            # Convert binary data to plain text
            try {
                $plainTextPassword = [System.Text.Encoding]::UTF8.GetString($bytes)
                Write-Host "Plain text password:" $plainTextPassword
            } catch {
                Write-Host "Error: Unable to convert binary data to plain text."
            }
        }
    } else {
        Write-Host "Error: The input is not a valid Base-64 string format."
    }
}

# Example usage
# Should equal: Plain text password: P@ssw0rd123
$exampleBase64Password = "UEBzc3cwcmQxMjM="
Decode-Base64Password -base64Password $exampleBase64Password
