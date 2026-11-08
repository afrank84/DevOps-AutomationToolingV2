# ARMA Cold War Assault add-on cleanup

## [Remove-Addons.ps1](Remove-Addons.ps1)

Defines `Remove-SpecifiedFilesAndFolder`, deletes a configured list of seven
BAS/JAM `.pbo` files, and recursively deletes the configured `BAS_Isle_Anim`
directory. It checks paths and prints found/missing/deletion messages.

Requires PowerShell and delete access to the game directory. Edit `$mainFolder`,
`$fileNames`, and `$targetFolder` in a local copy to match your installation, then
run the script. The shipped path is under `D:\Steam\steamapps\common\ARMA Cold
War Assault\AddOns`. There are no script-level arguments; the final call runs
immediately, including when dot-sourced.

Deletion uses `-Force` and directory `-Recurse`, with no confirmation or undo.
Back up add-ons first and close the game. The optional target folder is accepted
independently and is not restricted to the main folder. Some nonterminating
PowerShell errors can escape the intended catch behavior. Source was reviewed;
game files were not changed.
