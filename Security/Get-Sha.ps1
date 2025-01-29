param (
    [string]$Path = ".",  # Default to current directory
    [string]$Algorithm = "SHA256"  # Default to SHA256
)

# Function to compute SHA hash of a file
function Get-FileHashInfo {
    param (
        [string]$FilePath,
        [string]$Algorithm
    )

    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm $Algorithm
        [PSCustomObject]@{
            FileName = $hash.Path
            Hash     = $hash.Hash
        }
    } catch {
        Write-Host "Error processing file: $FilePath - $_" -ForegroundColor Red
    }
}

# Get all files in the specified directory
$files = Get-ChildItem -Path $Path -File

# Compute and display hashes
$hashList = $files | ForEach-Object { Get-FileHashInfo -FilePath $_.FullName -Algorithm $Algorithm }

# Display results in table format
$hashList | Format-Table -AutoSize
