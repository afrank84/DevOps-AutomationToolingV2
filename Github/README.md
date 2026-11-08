# GitHub API and workstation utilities

These tools are independent examples with different authentication methods.
Credentials/configuration belong in local settings; do not commit a token or
publish an HTML page containing a token. The explanations below come from source
review; no repository, runner, or remote file was changed to verify them.

## [Get-AllReposPrivateAndPublic.pl](Get-AllReposPrivateAndPublic.pl)

Uses Perl `HTTP::Tiny` and `JSON::PP` to GET the authenticated user's repositories,
following GitHub's `Link` next-page headers. Requires `GITHUB_PAT` in the process
environment with read access to the desired private repositories. Run
`perl Github/Get-AllReposPrivateAndPublic.pl`. It prints owner/repo, visibility,
fork status, default branch, and count; it does not clone repositories. HTTP
failures stop the run. Token scope/installation access determines the visible set.

## [Get-GitHubUserInformationViaApi.ps1](Get-GitHubUserInformationViaApi.ps1)

Defines and immediately calls `Get-GitHubUserInfo`. Prompts for a username and
whether to output JSON, GETs `/users/<user>` with `Invoke-RestMethod`, and prints
the returned public profile properties or JSON. Run in PowerShell; requires
api.github.com access and no configured token. It does not fetch private account
details or paginate other resources. See the [older detailed note](Get-GitHubUserInformationViaApi_README.md).

## [Get-ListOfPublicRepositoriesByUsername.ps1](Get-ListOfPublicRepositoriesByUsername.ps1)

Prompts for a username, GETs `/users/<user>/repos` unauthenticated, and prints each
name and HTML URL. Run the file in PowerShell with GitHub API access. There is no
pagination, so this is only the first response page, not necessarily every public
repository. No local files or remote records are changed.

## [Get-CsprojCommitsVsAllCommitsInGithubCli1Year.pl](Get-CsprojCommitsVsAllCommitsInGithubCli1Year.pl)

Uses Perl and an authenticated `gh` CLI to discover the default branch and its
`.csproj` files, fetch commits per path within configured dates, deduplicate by
SHA, then compare monthly counts against all commits. Configure `$repo`, `$since`,
and `$until` at the top; run with Perl. Requires `JSON::PP`, `Time::Piece`,
`File::Path`, `gh`, and read access to the target repository. Writes timestamped
detail/summary CSVs under `~/Documents/github_csproj_commit_stats`.

Limits: concatenated `gh api --paginate` arrays may not decode as one JSON array;
errors are suppressed/skipped in places, recursive tree truncation is not checked,
and a commit touching multiple project files is recorded only once. Treat a zero
or low count as something to investigate, not proof of no changes.

## [Get-Commits.php](Get-Commits.php)

Uses PHP cURL to fetch up to 100 commits from the configured owner/repository,
group them by author month, and emit an HTML list of SHA, author, date, and message.
Set `$owner`, `$repo`, and optionally `$token`; run through PHP with cURL enabled.
No next pages are requested and HTTP error bodies are not validated as commit
arrays. HTML fields are not escaped. It reads remote data but writes no commits.

## [List-IssuesOnSite.php](List-IssuesOnSite.php)

Server-side PHP snippet fetching the first page of default open issues from a
configured public repository. It sets a User-Agent and prints escaped titles,
bodies, state, and GitHub links. Requires PHP URL stream access and network access;
set `$owner`/`$repo` before execution. GitHub's issues endpoint can include pull
requests. It neither authenticates for private data nor paginates or creates issues.
Cloudflare's static Pages host does not execute PHP; this needs a PHP server.

## [Get-MarkdownFileAndDisplayFromGithub.html](Get-MarkdownFileAndDisplayFromGithub.html)

Browser form accepting a GitHub `blob/<branch>/<path>` URL, converting it to a
Contents API request, fetching raw Markdown, and rendering it with a CDN-hosted
Marked parser. Open the HTML explicitly and submit a public Markdown URL. It
requires GitHub API/CDN access, has no authentication, and assumes a single URL
segment for the branch. The original example inserts rendered HTML without
sanitization and logs fetched content to the console; use only trusted content.
The site's new guide reader uses separate sanitized rendering.

## [Update-GithubTxtFileInRepoWithJavaScript.html](Update-GithubTxtFileInRepoWithJavaScript.html)

Browser form GETs a configured repository file's SHA, then PUTs Base64-encoded
textarea content and a commit message using the Contents API. Configure owner,
repository, path, and token only in a private local working copy; opening a
publicly hosted token-bearing page exposes that credential. Requires target
Contents write permission. Submission creates a commit and replaces content;
it does not merely preview text. `btoa` does not directly support arbitrary
Unicode, HTTP status checks are missing, and nonexistent-file handling is not
robust despite the message mentioning creation.

## [Get-MdChangesLocally.ps1](Get-MdChangesLocally.ps1)

Defines `Search-MDFilesForLine`, scans `.md` files recursively, and prints filenames
whose first ten lines match a configured regex (default `github publish: true`).
The final call contains a hardcoded Windows directory. Adjust that call in a
local copy, then run in PowerShell. It does not compute Git diffs or publish
Markdown. Only the first ten lines are searched; it does not modify files.

## [Get-RunnerGroups.sh](Get-RunnerGroups.sh)

A curl GET example for `/orgs/<org>/actions/runner-groups` with a bearer-token
placeholder. Configure the organization and token in a private local copy, then
invoke with Bash/curl under credentials permitted to read organization runner
groups. It prints the raw JSON response; there is no pagination, status handling,
or runner reconfiguration. Do not confuse organization access with repo write access.

## [Test-IfGitHubActionRunnerServiceIsRunningOnWindowsAgent.ps1](Test-IfGitHubActionRunnerServiceIsRunningOnWindowsAgent.ps1)

Uses PowerShell remoting to the hardcoded computer placeholder, enumerates services
whose display names start with `GitHub`, and prints each status. Configure the
computer name and ensure Windows remoting and your account permissions work before
running. It neither starts services nor confirms that a runner is registered or
able to accept jobs; its no-services message is broader than the actual query.

## [Synology-DownloadAllReposInAccount.sh](Synology-DownloadAllReposInAccount.sh)

Uses curl to request up to 100 repositories from `/users/<username>/repos`,
extracts SSH URLs with grep, and clones missing checkouts or runs `git pull origin
main` in existing directories. Set `USERNAME`, `TOKEN`, and `BASE_DIR` in a local
copy; requires Bash, curl, grep, Git, SSH authentication, and writable storage.
The token authenticates the API request; it does not authenticate SSH clones.
It is not paginated, does not guarantee private repository discovery, assumes
`main`, and modifies existing working trees. Review local changes before pulling.

## [HighCommitCount.html](HighCommitCount.html)

Interactive GitHub file-churn analyzer. Open the HTML, select owner/repository,
branch/date range and grouping controls, then analyze. It requests commits and
details through the GitHub API, renders trend/scatter charts and file tables,
supports file previews, and exports CSV. Needs browser/network support for its
chart assets and API calls; private repository reads need a permitted token.

The token and owner are saved to `localStorage` on that origin, so do not use
shared browser profiles. Large histories require many requests and can hit API
limits; analysis is a change-frequency view, not proof of defects or author
productivity. Source previews and exports are read operations, not commits.

## [changeMyDataWithApiFromJsScript.txt](changeMyDataWithApiFromJsScript.txt)

This tracked file is currently empty. It has no executable behavior or setup
steps. The similarly named browser API example above targets a separately
configured repository path; do not assume opening this text file performs an update.
