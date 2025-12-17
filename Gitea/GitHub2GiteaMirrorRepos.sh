#!/usr/bin/env bash
# Bulk mirror all repositories from a GitHub user into a Gitea instance
# Preserves full git history (branches, tags, commits)

GITHUB_USER="GITHUB_USERNAME"
GITEA_BASE="http://GITEA_HOST:PORT/GITEA_USERNAME"

mkdir -p gh_mirror
cd gh_mirror || exit 1

# Requires GitHub CLI (gh) to be installed and authenticated
gh repo list "$GITHUB_USER" --limit 200 --json name -q '.[].name' | while read -r repo; do
  echo "Mirroring repository: $repo"

  # Clone full repository metadata (all refs, branches, tags)
  git clone --mirror "https://github.com/$GITHUB_USER/$repo.git"

  cd "$repo.git" || exit 1

  # Add Gitea as a remote and push everything
  git remote add gitea "$GITEA_BASE/$repo.git"
  git push --mirror gitea

  cd ..
done
