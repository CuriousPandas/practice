#!/usr/bin/env bash
# Checks one practice pull request. The only change allowed is adding or
# editing visitors/<author>.md, and that file must be short plain text.
#
#   scripts/check-visitor.sh <base-commit> <head-commit> <author-login>
#
# Problems print as GitHub annotations, so the reason shows on the pull request
# itself rather than only in the log. Exits 1 on any problem, 2 on misuse.
set -euo pipefail

base=${1:-} head=${2:-} login=${3:-}
MAX_BYTES=500

# An empty login would make the expected path "visitors/.md" and every real
# file would fail with a confusing message - refuse loudly instead.
if [ -z "$base" ] || [ -z "$head" ] || [ -z "$login" ]; then
  echo "::error::usage: check-visitor.sh <base> <head> <login> (got base='$base' head='$head' login='$login')"
  exit 2
fi

# Paths come from strangers. Workflow commands are parsed from stdout, so a
# filename containing "::" or a newline could forge one; print a safe copy.
safe() { printf '%s' "$1" | tr -c 'A-Za-z0-9._/-' '?'; }

expected="visitors/${login,,}.md"
problems=0
fail() { echo "::error$1::$2"; problems=$((problems + 1)); }

seen=0
mine=''
# -z keeps odd filenames intact; --no-renames reports a rename as delete + add,
# so moving someone else's file is caught as deleting it.
while IFS= read -r -d '' status && IFS= read -r -d '' path; do
  seen=$((seen + 1))
  shown=$(safe "$path")
  # GitHub logins are case-insensitive, and learners often type theirs lower-case.
  if [ "${path,,}" != "$expected" ]; then
    fail " file=$shown" "This pull request may only add or change $expected. It also touches $shown - undo that change and push again."
  elif [ "$status" = D ]; then
    fail " file=$shown" "This deletes $shown. Add or edit it instead."
  else
    mine=$path
  fi
done < <(git diff --name-status -z --no-renames "$base" "$head")

if [ "$seen" -eq 0 ]; then
  fail '' "This pull request changes nothing. Add $expected and push again."
fi

if [ -n "$mine" ]; then
  # Read the file as committed, not from the working tree, so what is checked
  # is exactly what would be merged.
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  git show "$head:$mine" > "$tmp"
  bytes=$(wc -c < "$tmp")
  if [ "$bytes" -eq 0 ]; then
    fail " file=$mine" "$mine is empty. Write a line or two about yourself."
  elif [ "$bytes" -gt "$MAX_BYTES" ]; then
    fail " file=$mine" "$mine is $bytes bytes; keep it under $MAX_BYTES."
  fi
  if [ "$(tr -d '\000' < "$tmp" | wc -c)" -ne "$bytes" ]; then
    fail " file=$mine" "$mine is not plain text."
  fi
  # Links are what make a public, anyone-can-write file worth spamming.
  if grep -Eiqn 'https?://|www\.' "$tmp"; then
    line=$(grep -Ein 'https?://|www\.' "$tmp" | head -1 | cut -d: -f1)
    fail " file=$mine,line=$line" "No links, please - this file is about you, not a website."
  fi
fi

if [ "$problems" -gt 0 ]; then
  echo "$problems problem(s). Fix them on your branch and push; this check runs again by itself."
  exit 1
fi
echo "All good: $mine is the only change, and it is short plain text."
