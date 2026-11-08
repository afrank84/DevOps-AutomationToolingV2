# Move downloaded MP3 files

## [Move-Mp3Files.ps1](Move-Mp3Files.ps1)

Defines and immediately calls `Move-Mp3Files`, creating the destination if absent
and moving immediate `*.mp3` files with `Move-Item -Force`. Subdirectories are not
searched and other formats stay in place. It prints per-file messages and the
number of discovered MP3 files.

Requires PowerShell and read/write/delete access. Configure the final call's
`SourceFolder` and `DestinationFolder` in a local copy, then run the script. The
shipped call moves from `D:\Videos\SnapDownloader` to `D:\Music`. Dot-sourcing
also executes that call. Existing destination names can be overwritten; there
is no preview, confirmation, rollback, or explicit per-file success count.
The script was reviewed, not run.
