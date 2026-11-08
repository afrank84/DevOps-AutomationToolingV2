# YouTube audio and thumbnail utilities

These tools download media or process local images. The commands below describe
source behavior; no downloads or package installations were performed to test them.

## [Get-Mp3AudioFileFromYouTubeUrl.py](Get-Mp3AudioFileFromYouTubeUrl.py)

An interactive loop asks for a YouTube URL, passes it to `yt_dlp.YoutubeDL` with
`bestaudio/best`, then uses its FFmpeg audio postprocessor to produce MP3 at the
configured 192 quality. Requires Python, the `yt-dlp` package, FFmpeg on PATH,
and network access to the requested content.

```bash
python YouTube/Get-Mp3AudioFileFromYouTubeUrl.py
```

Files use yt-dlp's default naming and download location (the current directory).
After each attempt enter `1` to repeat or another integer to exit. Non-integer
input at that prompt is not handled. Download exceptions print a generic message;
URL accessibility and playlist behavior follow yt-dlp defaults.

## [GUI-Get-Mp3AudioFileFromYouTubeUrl.py](GUI-Get-Mp3AudioFileFromYouTubeUrl.py)

Provides the same yt-dlp/FFmpeg MP3 extraction via a Tkinter URL field and Download
button. Requires the same tools plus Tkinter and a graphical desktop.

```bash
python YouTube/GUI-Get-Mp3AudioFileFromYouTubeUrl.py
```

Enter a URL and click Download. Empty input shows a warning; exceptions show an
error dialog. Downloads run on the GUI thread, so the window can become
unresponsive while working. Output uses the current directory and yt-dlp defaults.

## [download-thumbnails.sh](download-thumbnails.sh)

Runs `sudo apt update`, installs `yt-dlp` and `ffmpeg`, creates
`~/YouTube-Thumbnails`, and loops over a channel's videos, shorts, and streams.
It downloads thumbnails only and converts them to JPG with title/ID filenames.

Replace `@YOURCHANNEL` in a local copy, then on an apt-based Linux machine:

```bash
bash YouTube/download-thumbnails.sh
```

This changes system packages and writes to your home directory. It needs sudo,
apt repositories, and YouTube access. `--ignore-errors` lets individual failures
continue; inspect yt-dlp output for missing images. It does not download video.

## [add-logo.sh](add-logo.sh)

Uses ImageMagick's `identify` and `convert` to overlay `logo.png` on non-hidden
JPG/JPEG/PNG/WebP files in the current directory. The logo is resized to 15% of
each image's width, shadowed, and placed at the bottom right with a 2% margin.

From a directory containing your images and `logo.png`, invoke the script by its
absolute path:

```bash
bash /path/to/DevOps-AutomationToolingV2/YouTube/add-logo.sh
```

Install ImageMagick separately. Output is `./output/<basename>.png`; originals
are kept, but existing output and equal basenames with different extensions can
be overwritten. It skips `logo.png`, ignores unmatched globs, and stops on a
failed command because `set -euo pipefail` is enabled.
