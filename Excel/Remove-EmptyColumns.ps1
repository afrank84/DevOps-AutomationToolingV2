function Remove-EmptyColumnsFromCsv {
    param (
        [string]$inputFilePath,
        [string]$outputFilePath
    )

    # Read the CSV file
    $data = Import-Csv -Path $inputFilePath

    # Get the headers
    $headers = $data[0].PSObject.Properties.Name

    # Initialize an array to hold columns with data
    $columnsWithData = @()

    # Check each column for data
    foreach ($header in $headers) {
        if ($data | Where-Object { $_.$header -ne $null -and $_.$header -ne "" }) {
            $columnsWithData += $header
        }
    }

    # Create a new CSV file with only columns that have data
    $data | Select-Object -Property $columnsWithData | Export-Csv -Path $outputFilePath -NoTypeInformation

    Write-Output "CSV file processed and saved to $outputFilePath"
}

# Example usage
# Remove-EmptyColumnsFromCsv -inputFilePath "path\to\your\input.csv" -outputFilePath "path\to\your\output.csv"
