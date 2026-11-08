# Podcast download-link listing

## [tbc_podman.sh](tbc_podman.sh)

Despite the filename, this is a curl/grep/sed webpage scraper, not a Podman
container command. Fetches a hardcoded Podbean page, matches anchor tags whose
visible text is exactly Download, prefixes relative links with the page URL,
and prints URLs. It does not download audio or traverse further pages.

Run `bash Podcast/tbc_podman.sh` with curl, GNU grep supporting `-P`, sed, and
network access. Edit `url` in a local copy for another compatible page. The regex
depends on the site's HTML and fails on many multiline/changed layouts; simple
URL concatenation also mishandles some relative paths. curl HTTP failures are
not checked. No podcast page was fetched to verify this guide.
