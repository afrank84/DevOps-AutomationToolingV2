# Action camera file management

These utilities organize local media. They operate on real files, not a catalog
or a database. Usage below is based on source review; the tools were not run.

## [Delete-All-Files-But-Mp4.pl](Delete-All-Files-But-Mp4.pl)

**What it does:** recursively scans a directory, keeps files whose names end in
`.mp4` (case-insensitive), and permanently deletes every other regular file after
confirmation. It displays before/after counts and previews up to 50 candidates.

**Requirements:** Perl with the standard `File::Find`, `Cwd`, and `File::Spec`
modules; read and delete access to the target tree. No camera connection is needed.

```bash
perl Action5Pro/Delete-All-Files-But-Mp4.pl --dir /path/to/copied-media
```

Without `--dir`, it prompts for a path. The exact confirmation word is `delete`
(case-insensitive). Anything else cancels. Work from a backup: photos, subtitles,
logs, and metadata are included in the deletion, and there is no recycle bin or
undo. Directories remain. Individual unlink failures are printed as warnings.

## [Organize-AllVideosByMonth.sh](Organize-AllVideosByMonth.sh)

**What it does:** examines non-hidden regular files directly inside one directory,
reads each file's modification month, creates `YYYY-MM` subdirectories, and moves
the files into them with `mv -n` to avoid overwriting same-name destinations.
Despite its name it processes all non-hidden file types, not only videos.

**Requirements:** Bash, `find`, `date -r`, `mkdir`, and `mv`. The timestamp is the
filesystem modification time, not EXIF data or the camera recording date.

```bash
bash Action5Pro/Organize-AllVideosByMonth.sh /path/to/copied-media
```

The argument defaults to the current directory. It is not recursive. Existing
destination files are skipped by `mv -n`; check for files left in the original
directory. Filenames containing newlines are not handled correctly by its
line-based `find` loop. There is no preview or confirmation before moving files.
