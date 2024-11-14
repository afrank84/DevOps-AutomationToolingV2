# Define the BBC News RSS feed URL
$rssUrl = "https://feeds.bbci.co.uk/news/world/rss.xml"

# Fetch and parse the RSS feed
try {
    $rssFeed = [xml](Invoke-WebRequest -Uri $rssUrl -UseBasicParsing).Content
} catch {
    Write-Error "Failed to retrieve the RSS feed. Please check your internet connection or the feed URL."
    return
}

# Display the channel title
$channelTitle = $rssFeed.rss.channel.title.'#cdata-section'
Write-Output "Channel: $channelTitle"
Write-Output "====================="

# Iterate over each item in the RSS feed
foreach ($item in $rssFeed.rss.channel.item) {
    $title = $item.title.'#cdata-section'
    $description = $item.description.'#cdata-section'
    $link = $item.link
    $pubDate = $item.pubDate

    # Output the news item details
    Write-Output "Title: $title"
    Write-Output "Published: $pubDate"
    Write-Output "Description: $description"
    Write-Output "Link: $link"
    Write-Output "---------------------"
}
