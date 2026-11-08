# ROM selection cleanup

## [RemoveGamesForKids.pl](RemoveGamesForKids.pl)

Perl utility recursively matching a configured set of game-title patterns under
PSP, PS1, CPS2, and FBeno paths. Run
`perl AmbernicRG35XXSP/RemoveGamesForKids.pl /path/to/copied-roms`; the path defaults
to the current directory. It requires standard Perl modules and delete access.

It prints numbered matches, then accepts `y` to delete all, `n` to cancel, or
comma-separated indexes to delete selected matches with `unlink`. Deletion is
permanent. The patterns are a literal title list, not a content-rating database,
and cannot establish that other games are suitable for children. Review paths
and keep backups; the script does not remove database entries or launch games.
Source review only; no ROMs were scanned or deleted.
