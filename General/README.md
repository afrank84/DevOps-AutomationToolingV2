# General utilities

Independent filesystem, Windows reporting, and timer tools. Usage is based on
reading source; none of these scripts was run for documentation. For Windows
files, use Windows PowerShell and review assigned paths in a local copy first.

## [Backup-ImagesFromAndroidPhone.ps1](Backup-ImagesFromAndroidPhone.ps1)

Copies immediate files from the configured mounted camera directory to a backup
directory. It loads success **and failure** logs into a skip table, prints human
readable sizes, attempts `Copy-Item`, appends results, and waits two seconds per
file. Set `$SourceDir`, `$DestDir`, `$LogFile`, and `$FailedLogFile`, ensure output
directories exist, and run the script. It does not use ADB or recurse. Previously
failed files are skipped on later runs. `Safe-Copy` is called without its
`FailedLogFile` argument, so its internal failure logging can itself fail; outer
messages are not proof of a complete backup. No content checksum is compared.

## [Copy-AllImagesToNewFolder.py](Copy-AllImagesToNewFolder.py)

Python/Tkinter GUI recursively collects recognized image extensions into one
destination using `shutil.copy2`. Run `python General/Copy-AllImagesToNewFolder.py`,
choose separate source/destination directories, then Copy Images. It creates the
destination and suffixes collisions with `_1`, `_2`, etc. rather than overwriting.
It flattens directory structure and leaves originals. Keep the destination outside
the source to avoid discovering copied files during traversal. Blank selections
can resolve to the current directory; select both paths explicitly. The skipped
counter is never incremented, so its reported skipped count is not a coverage check.

## [Find-DuplicateFiles.sh](Find-DuplicateFiles.sh)

Reports duplicate **basenames**, not equal content. Requires Bash 4+ associative
arrays and `find`. Run `bash General/Find-DuplicateFiles.sh /path/to/tree` (default
current directory). It counts regular files recursively and prints every location
for repeated names. It uses NUL-separated discovery, does not delete anything,
and suppresses find errors; inaccessible directories can be absent from results.

## [organize.sh](organize.sh)

Recursively moves recognized document/image/video extensions from Downloads into
Documents/Pictures/Movies. Run with Bash after reviewing the hardcoded home-based
source/destination variables. It needs `find` and `mv`; destination directories
must exist. It flattens names and has no collision protection, preview, or
confirmation, so same-name files can overwrite each other. Unrecognized files stay.

## [Remove-FilesBackupsByFibonacci.ps1](Remove-FilesBackupsByFibonacci.ps1)

Scans immediate backup directories whose names contain an eight-digit `yyyyMMdd`.
Keeps today's folder and ages equal to Fibonacci intervals up to the configured
233-day maximum; recursively force-deletes other matching folders. Configure
`$backupFolder` and `$fibonacciMaxDays`, then run in PowerShell only after backing
up the tree. There is no dry run. It parses the first matched date and can fail
on invalid date strings. This is exact-day retention, not a scheme ensuring the
nearest available backup for each interval.

## [RoboCopy-TransferHost2Host.ps1](RoboCopy-TransferHost2Host.ps1)

Windows Robocopy transfer wrapper. Configure source share and destination root;
it appends the source leaf name to the destination, copies subdirectories including
empty ones with `/E`, copies all metadata with `/COPYALL`, uses 16 threads, and
retries once with a one-second wait. Run with share and metadata-copy permissions.
It writes a timestamped log in TEMP and accepts Robocopy exit codes 0–7, throwing
above 7. It is a copy, not `/MIR`, so extra destination files are not purged.

## [Get-DiskSpaceOfPhysicalOrVirtualMachine.ps1](Get-DiskSpaceOfPhysicalOrVirtualMachine.ps1)

Reports local computer name, C: capacity/free space, and physical memory using WMI
on older PowerShell and CIM on PowerShell 7+. Run on Windows with access to those
providers. A separate manufacturer/model check labels only Microsoft models
containing `Virtual` as virtual; other VM platforms may be mislabeled physical.
Output is terminal-only and does not change disk or memory settings.

## [Get-WindowsKey.ps1](Get-WindowsKey.ps1)

Reads the Windows `DigitalProductId` registry value and applies a base-24 decoding
loop to print a hyphenated key. Run on Windows with read access to HKLM. It does
not activate Windows or retrieve every OEM/digital entitlement; the computed key
may not represent the current usable license. Treat printed output as sensitive.

## [List-OfProgramsInstalled.ps1](List-OfProgramsInstalled.ps1)

Reads HKLM's standard Uninstall registry entries, selects nonempty display names,
and writes a formatted table of name, install date, and publisher to
`InstalledPrograms.txt` on the current user's Desktop. Run in Windows PowerShell.
It overwrites that report and does not enumerate every per-user, 32-bit, or Store
installation. It neither installs nor removes programs.

## [List-WindowsUpdates.ps1](List-WindowsUpdates.ps1)

Queries `Get-HotFix`, requests a combined KB search from the Microsoft Update
Catalog, and tries to regex-parse titles into a terminal table. Requires Windows
PowerShell and catalog access. Run the script directly; no arguments are taken.
Catalog HTML parsing is fragile, and the nested filter compares `KBID` with
`HotFixID` on the inner object rather than preserving the outer hotfix, so online
titles may not join correctly. No updates are installed.

## [timer_gui.py](timer_gui.py)

Local Python/Tkinter countdown with minute/second inputs, Start, Pause/Resume,
Reset, and completion beep. Run `python General/timer_gui.py` on a graphical
desktop. Inputs must be whole nonnegative numbers, seconds 0–59, and a positive
total. Tk `after` schedules ticks and callbacks are canceled on close/reset.
It writes no files. Its first decrement happens immediately and timing uses
scheduled ticks, so do not use it as a precision timekeeper.

## [KidsCountDownTimer.py](KidsCountDownTimer.py)

Python/Tkinter task timer with an initial five-hour bank, optional bank deduction,
pause/resume, and a password-gated reset. Run with Python/Tkinter, enter a task
name and minutes, choose bank deduction, then Start Task. Completion appends
`task_log.csv` in the working directory; bank state resets on restart. The parent
password is hardcoded, not an access-control boundary. A worker thread updates
Tk widgets directly, and paused timing uses a busy loop; use as an experimental
desktop utility rather than an authoritative time/accounting record.

## [timer.html](timer.html)

Standalone browser countdown. Open this HTML explicitly after reviewing it, set
hours/minutes/seconds, and use Start/Pause, Reset, and Fullscreen. Space, R, and F
provide shortcuts. It tracks a `performance.now()` deadline, renders red at zero,
and keeps all state in memory; refresh resets to five minutes. No backend, log,
or alarm sound is provided. Fullscreen needs browser support and a user action.

## [Search-KeywordOccurence.cob](Search-KeywordOccurence.cob)

Draft COBOL program intended to read `keywords.txt` and `input.txt`, count matches,
and write `output.txt` in the working directory. It declares ten keyword slots,
20-character keyword fields, and 80-character records. Requires a COBOL compiler,
but the current substring declarations/expressions and loop structure need review
and correction before a reliable build/run can be documented. It opens output
with overwrite behavior and has no robust file-status handling. Do not treat its
intended output as verified keyword counts.
