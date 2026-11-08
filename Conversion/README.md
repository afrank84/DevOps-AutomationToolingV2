# File conversion utilities

This folder contains independent Python and PowerShell utilities. The Python
tool converts CSV records to JSON. The PowerShell tool copies HTML files to
Markdown filenames; it **does not convert HTML syntax into Markdown syntax**.

These explanations were checked against the source; the scripts were not run.

## CSV records to JSON

Source: [Convert-CsvToJson.py](Convert-CsvToJson.py).

Use this when a CSV table should become a JSON array of objects, with CSV column
headers as keys. It requires Python and pandas. The source mentions pandas
1.3.3 in a comment, but does not enforce a version or provide a dependency lock.
Choose a pandas release compatible with your Python environment.

From the repository root, in an environment with pandas installed:

```bash
python Conversion/Convert-CsvToJson.py path/to/input.csv
```

The script uses the last command-line argument as its input path, checks that
it exists and has a lowercase `.csv` suffix, reads it with `pandas.read_csv`,
and writes `path/to/input.json` using `orient='records'`. Relative paths resolve
against your current working directory. There are no custom delimiter, encoding,
or type options; pandas defaults determine parsing and serialization.

For a CSV containing `name,count` and `example,2`, the intended JSON shape is:

```json
[{"name":"example","count":2}]
```

**Outputs and limitations:** the JSON file is beside the input and an existing
file with that name can be overwritten. The CSV is not modified. Missing
arguments exit with status 1, but directory inputs and caught conversion errors
only print messages; a successful process exit is not proof of conversion.
Inspect the success message and output file. The complete table is loaded into
memory, so size the environment for the input.

The [older CSV note](Convert-CsvToJson.md) is preserved for reference; the command
above uses the actual filename in this repository.

## Copy HTML content to `.md` files

Source: [Get-AllContentHtmlToMd.ps1](Get-AllContentHtmlToMd.ps1).

Use this only when you want byte-for-byte HTML content under Markdown filenames.
It needs PowerShell and filesystem access to the chosen directory. It defines
`Copy-HtmlToMd`, recursively finds `*.html` files, changes each destination suffix
to `.md`, and invokes `Copy-Item -Force`. Original HTML files remain in place.

The script ends by calling the function against a hardcoded Windows path.
Before execution, review a local working copy and replace that final call with
the intended directory, for example:

```powershell
Copy-HtmlToMd -RootDirectory "C:\path\to\reviewed-html"
```

That is the function invocation inside the script, not a command-line parameter
accepted by the script file. Running the unchanged script targets its shipped
`D:\stash\DevOps-PowerShellAutomation\` path. Dot-sourcing it also executes the
final call, so do not dot-source it merely to load the function.

**Outputs and side effects:** existing sibling `.md` files are overwritten by
`-Force`, and the script prints `Created file: ...` for each iteration. It does
not parse HTML, rewrite links, preserve a prior README, or verify Markdown
rendering. The directory parameter must identify an existing container. There
is no explicit stop-on-error or per-copy success verification, so inspect errors
and files rather than treating printed messages as a completion guarantee.
