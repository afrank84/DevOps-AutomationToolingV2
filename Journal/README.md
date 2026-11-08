# Event journal

## [Write-EventToTextFile.ps1](Write-EventToTextFile.ps1)

Prompts `Describe what just happened`, gets the current timestamp, and appends
`timestamp | author : response` to `../Data/event_journal.txt`. Set the literal
`$author` assignment in a local copy before using it. It needs PowerShell and
write access to the destination.

The destination is relative to the **working directory**, not the script path.
To use the repository's Data directory:

```powershell
Set-Location Journal
.\Write-EventToTextFile.ps1
```

It appends rather than replaces the journal and prints a thank-you message.
There is no structured escaping, encryption, validation, or author authentication.
These instructions are source-reviewed; no journal entries were created.
