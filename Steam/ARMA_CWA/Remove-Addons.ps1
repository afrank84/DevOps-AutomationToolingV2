function Remove-SpecifiedFilesAndFolder {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory = $true)]
        [string[]]$FileNames,
        
        [Parameter(Mandatory = $false)]
        [string]$TargetFolder
    )

    # Check if the main folder exists
    if (-Not (Test-Path -Path $FolderPath)) {
        Write-Host "Main folder does not exist: $FolderPath" -ForegroundColor Red
        return
    }

    # Remove the specified files
    foreach ($fileName in $FileNames) {
        $filePath = Join-Path -Path $FolderPath -ChildPath $fileName
        
        if (Test-Path -Path $filePath) {
            try {
                Remove-Item -Path $filePath -Force
                Write-Host "Deleted file: $filePath" -ForegroundColor Green
            } catch {
                Write-Host "Failed to delete file: $filePath. Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "File not found: $filePath" -ForegroundColor Yellow
        }
    }

    # Remove the target folder recursively
    if ($TargetFolder) {
        if (Test-Path -Path $TargetFolder) {
            try {
                Remove-Item -Path $TargetFolder -Recurse -Force
                Write-Host "Deleted folder: $TargetFolder" -ForegroundColor Green
            } catch {
                Write-Host "Failed to delete folder: $TargetFolder. Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Folder not found: $TargetFolder" -ForegroundColor Yellow
        }
    }
}

# Example usage
# Define the main folder, filenames, and the target folder to delete
$mainFolder = "D:\Steam\steamapps\common\ARMA Cold War Assault\AddOns"
$fileNames = @(
    "BAS_I1.pbo",
    "BAS_I2.pbo",
    "BAS_O.pbo",
    "BAS_OPCPP.pbo",
    "BAS_OPFOR.pbo",
    "JAM_Magazines.pbo",
    "JAM_Sounds.pbo"
)
$targetFolder = "D:\Steam\steamapps\common\ARMA Cold War Assault\AddOns\BAS_Isle_Anim"

# Call the function
Remove-SpecifiedFilesAndFolder -FolderPath $mainFolder -FileNames $fileNames -TargetFolder $targetFolder
