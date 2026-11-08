# Outlook message export

## [Convert-MsgToMd.ps1](Convert-MsgToMd.ps1)

Uses Windows Outlook COM and Office interop to open immediate `.msg` files in a
configured directory, read Subject and plain-text Body, close each item without
saving, and write a sibling `.md` containing a subject heading and body. Existing
Markdown files are skipped. Attachments, rich formatting, and message metadata
are not exported.

Requires Windows, classic Outlook with COM/interop available, PowerShell, and
filesystem access. Change the final `Convert-MSGFilesToMarkdown -sourceDirectory`
call in a local copy to your directory, then run the script. The call executes
immediately, also when dot-sourced. Output encoding follows the PowerShell
runtime defaults; there is no recursive traversal or explicit COM cleanup.
Source-reviewed only; no Outlook session or messages were opened.
