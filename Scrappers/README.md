# Web extraction examples

## [Get-IcoFromWebsite.ps1](Get-IcoFromWebsite.ps1)

Fetches a configured website with `Invoke-WebRequest`, searches `$response.Links`
for hrefs containing `favicon.ico`, resolves relative URLs, and downloads to
`favicon.ico` in the working directory. Configure `$websiteUrl` in a local copy
and run in PowerShell with network/write access. It can overwrite the output.
Favicons are normally `<link>` metadata rather than anchors, so `$response.Links`
may find nothing; multiple matches also are not handled. It does not fall back
to `/favicon.ico`, parse modern icon manifests, or validate downloaded content.

## [PutnamCounty.ps1](PutnamCounty.ps1)

Fetches a hardcoded parcel URL and regex-extracts labeled ownership, valuation,
location, acreage, and assessment fields for terminal display. Configure `$url`
in a local copy and run with PowerShell/network access. It writes no database
or files. Results depend on the current response format and label spelling;
blank matches are not detected as errors. The printed 911-address text is a
static placeholder, not an extracted fact. It is not an authoritative property
record or a general county API client. Both descriptions are source-reviewed,
not live scraping tests.
