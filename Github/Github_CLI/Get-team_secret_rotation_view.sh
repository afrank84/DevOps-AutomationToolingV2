#!/usr/bin/env bash
set -euo pipefail

# Replace these with your actual org and team
ORG="your-org"
TEAM_SLUG="your-team"

ALL_FILE="secrets-all.json"
GROUPED_FILE="secrets-grouped.json"
DUPES_FILE="secrets-duplicates.json"

echo "Building combined secret list for team '$TEAM_SLUG' in org '$ORG'..."

# Start combined JSON array
echo "[" > "$ALL_FILE"
FIRST=1

# Collect all secrets (repo + env)
gh api "orgs/$ORG/teams/$TEAM_SLUG/repos" --paginate --jq '.[].name' | while read REPO; do
  [ -z "$REPO" ] && continue
  FULL_REPO="$ORG/$REPO"
  echo "  Processing repo: $FULL_REPO"

  # Repo-level secrets
  gh secret list --repo "$FULL_REPO" --json name 2>/dev/null | \
    jq -c --arg repo "$REPO" \
      '.[] | {repo: $repo, environment: "repo", secret: .name}' | \
    while read -r obj; do
      if [ $FIRST -eq 1 ]; then
        FIRST=0
      else
        echo "," >> "$ALL_FILE"
      fi
      echo "$obj" >> "$ALL_FILE"
    done

  # Environment-level secrets
  ENV_NAMES=$(gh api "repos/$FULL_REPO/environments" --jq '.environments[].name' 2>/dev/null || true)

  for ENV in $ENV_NAMES; do
    [ -z "$ENV" ] && continue
    echo "    Env: $ENV"

    gh secret list --repo "$FULL_REPO" --env "$ENV" --json name 2>/dev/null | \
      jq -c --arg repo "$REPO" --arg env "$ENV" \
        '.[] | {repo: $repo, environment: $env, secret: .name}' | \
      while read -r obj; do
        if [ $FIRST -eq 1 ]; then
          FIRST=0
        else
          echo "," >> "$ALL_FILE"
        fi
        echo "$obj" >> "$ALL_FILE"
      done
  done
done

echo "]" >> "$ALL_FILE"
echo "Done building $ALL_FILE"

# Group by secret name
echo "Grouping by secret name into $GROUPED_FILE..."
jq '
  group_by(.secret)
  | map({
      secret: .[0].secret,
      locations: map({repo, environment})
    })
' "$ALL_FILE" > "$GROUPED_FILE"

# Extract duplicates
echo "Extracting duplicates into $DUPES_FILE..."
jq '
  map(select(.locations | length > 1))
' "$GROUPED_FILE" > "$DUPES_FILE"

echo "Done."
echo "  All secrets:          $ALL_FILE"
echo "  Grouped by name:      $GROUPED_FILE"
echo "  Reused across repos:  $DUPES_FILE"
