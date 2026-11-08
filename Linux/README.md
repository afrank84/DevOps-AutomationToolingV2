# Linux utilities

## [Get-EnviormentVariablesInList.sh](Get-EnviormentVariablesInList.sh)

Runs `env`, splits each line on the first `=`, and prints a padded variable name
with its value. Requires Bash and standard `env`, `cut`, and `printf` tools.

```bash
bash Linux/Get-EnviormentVariablesInList.sh
```

There are no arguments, output files, or system changes. **It prints secret values
as well as ordinary settings.** Do not use it in shared build logs or support
transcripts; prefer listing variable names only when diagnosing credentials.
Multiline values are not preserved as a structured record. This behavior is
source-reviewed; the environment was not dumped to write this guide.
