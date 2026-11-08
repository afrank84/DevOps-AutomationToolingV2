# CSV column cleanup

## [Remove-EmptyColumns.ps1](Remove-EmptyColumns.ps1)

Defines `Remove-EmptyColumnsFromCsv`: imports a CSV, inspects each header, retains
columns with at least one non-null/nonempty value, and exports selected columns
without type information. Whitespace counts as data. This works on CSV files,
not Excel workbooks, and needs only PowerShell's CSV cmdlets.

The example call is commented out, so running the file alone only defines the
function in that process. Load it and invoke it in your session:

```powershell
. .\Excel\Remove-EmptyColumns.ps1
Remove-EmptyColumnsFromCsv -inputFilePath .\input.csv -outputFilePath .\cleaned.csv
```

Use a different output path to preserve the input. Export overwrites an existing
destination and uses the runtime's CSV encoding defaults. Empty/header-only input
is not robustly handled because the function indexes the first data row. This
guide is based on source review; no CSV was modified.
