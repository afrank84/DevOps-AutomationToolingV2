# GitHub-to-Gitea mirror template

## [GitHub2GiteaMirrorRepos.sh](GitHub2GiteaMirrorRepos.sh)

Lists up to 200 GitHub repositories with `gh repo list`, creates local bare
`git clone --mirror` checkouts under `./gh_mirror`, adds a Gitea remote, and uses
`git push --mirror` to transfer refs. Configure `GITHUB_USER` and `GITEA_BASE` in
a local copy and invoke with Bash. Requires Git, an authenticated `gh`, separate
Git clone/push authentication, and existing writable destination repositories.

**Mirror pushes can delete or replace destination refs.** This is not a noninvasive
backup command. It does not create Gitea repositories or migrate issues, users,
settings, or release attachments. The template Gitea URL uses HTTP; configure an
appropriate secure destination for your instance. There is no robust retry or
re-run handling for existing clone directories/remotes. No mirrors were pushed
to write this guide.
