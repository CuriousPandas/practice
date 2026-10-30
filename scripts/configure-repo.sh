#!/usr/bin/env bash
# Applies this repository's GitHub settings. Nothing else owns them, so this
# script is the source of truth: change a setting here and re-run it, never in
# the web UI, or a rebuild silently loses it. Safe to run repeatedly.
#
#   scripts/configure-repo.sh [owner/repo]     (needs gh, logged in as an admin)
set -euo pipefail
repo=${1:-CuriousPandas/practice}
cd "$(dirname "$0")/.."

gh api -X PATCH "repos/$repo" \
  -f description='Open a practice pull request here - the hands-on half of the Curious Pandas git lessons.' \
  -f homepage='https://learn.curiouspandas.dev/learn/git/collaborate/' \
  -F has_wiki=false -F has_projects=false -F has_discussions=false \
  -F delete_branch_on_merge=true > /dev/null

# GitHub's default makes every first-time contributor wait for a maintainer to
# approve their workflow run - here, that is every learner, and the lesson
# would stall on "awaiting approval". Brand-new GitHub accounts, the usual
# source of Actions abuse, still wait. Tighten to first_time_contributors if
# that ever proves too loose.
gh api -X PUT "repos/$repo/actions/permissions/fork-pr-contributor-approval" \
  -f approval_policy=first_time_contributors_new_to_github

gh label create keep-open --repo "$repo" --force --color 0e8a16 \
  --description 'tidy.yml will not auto-close this pull request' > /dev/null

# main: a pull request with one approval and a green visitor-file check.
# Repository admins (role 5) may bypass, for maintenance and the first push.
id=$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name == "main") | .id')
if [ -n "$id" ]; then
  gh api -X PUT "repos/$repo/rulesets/$id" --input .github/rulesets/main.json > /dev/null
else
  gh api -X POST "repos/$repo/rulesets" --input .github/rulesets/main.json > /dev/null
fi

# Read back what GitHub actually holds, so a silently ignored field shows up.
echo "settings:  $(gh api "repos/$repo" --jq '"wiki=\(.has_wiki) projects=\(.has_projects) delete_branch_on_merge=\(.delete_branch_on_merge)"')"
echo "approval:  $(gh api "repos/$repo/actions/permissions/fork-pr-contributor-approval" --jq .approval_policy)"
echo "ruleset:   $(gh api "repos/$repo/rules/branches/main" --jq '[.[].type] | join(", ")')"
