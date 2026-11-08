# RSS feed reader

## [BBC-NewsFeed.ps1](BBC-NewsFeed.ps1)

Fetches BBC's world-news RSS XML with `Invoke-WebRequest`, parses it with
PowerShell's XML type, and prints channel title plus each item's title,
publication date, description, and link. Run:

```powershell
.\RSS\BBC-NewsFeed.ps1
```

Requires PowerShell and access to `feeds.bbci.co.uk`. Change `$rssUrl` in a local
copy for another compatible RSS feed. It prints to the terminal and stores no
subscriptions or read history. Request/parse failures print an error and return.
Titles/descriptions are read specifically from CDATA child properties, so plain
text XML variants can show empty fields. No feed was fetched to author this guide.
