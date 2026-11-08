# Browser profile utilities

## [Get-BookMarks.py](Get-BookMarks.py)

Interactive Python utility that exports bookmarks from Brave, Chrome, or Firefox
to a tab-separated text file in the current working directory. It uses Python's
standard library; there are no third-party imports to install.

```bash
python Browsers/Get-BookMarks.py
```

Choose `1` (Brave), `2` (Chrome), or `3` (Firefox). The first two read the default
profile's `Bookmarks` JSON and recursively export only `bookmark_bar`; other
bookmark roots and non-default profiles are omitted. Firefox locates the first
profile ending in `.default` or `.default-release`, opens `places.sqlite`, and
joins bookmark and URL tables.

**Outputs:** `brave_bookmarks.txt`, `chrome_bookmarks.txt`, or
`firefox_bookmarks.txt`, with one `title<TAB>url` line per bookmark. Existing files
are overwritten. Paths are selected for Windows, macOS, or Linux from the
current user's profile. Missing profiles, malformed JSON, or a locked Firefox
database can raise exceptions; there is no recovery dialog. Close the browser
first if database access fails. The exported URLs may be private information.

## [Brave-RemoveLockFile.sh](Brave-RemoveLockFile.sh)

Deletes Brave's `SingletonLock`, `SingletonSocket`, and `SingletonCookie` entries
under `~/.config/BraveSoftware/Brave-Browser`. This is a Linux profile recovery
snippet, not a general browser repair tool.

```bash
bash Browsers/Brave-RemoveLockFile.sh
```

It requires Bash and filesystem access to that profile, has no arguments or
confirmation, and uses `rm -f`. Fully stop Brave first: removing lock entries
while the browser is active can allow conflicting profile access. It neither
kills Brave nor detects whether the lock is genuinely stale.

Both descriptions are based on source review; browser profiles were not changed.
