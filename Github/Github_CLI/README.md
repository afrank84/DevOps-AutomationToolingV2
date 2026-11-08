# GitHub CLI secret-name inventory

## [Get-team_secret_rotation_view.sh](Get-team_secret_rotation_view.sh)

Intends to list repositories visible to an organization team, collect repository
and environment secret **names**, group them, and report names reused across
locations. It does not read secret values or rotate any secret.

Requires Bash, `gh`, `jq`, and GitHub CLI authentication permitted to list the
team's repositories, environments, and Actions secret metadata. Configure `ORG`
and `TEAM_SLUG` in a local copy and invoke with Bash. It overwrites
`secrets-all.json`, `secrets-grouped.json`, and `secrets-duplicates.json` in the
working directory.

**Known source limitation:** `FIRST` is changed inside piped `while` subshells.
The comma state does not reliably survive between repositories/environment lists,
so combined output can be invalid JSON and grouping can fail. Secret-list errors
are also suppressed, which can yield incomplete results. Review/fix JSON assembly
before using this for rotation planning; repeated names do not establish shared
secret values or rotation dates. This was a source review, not an organization scan.
