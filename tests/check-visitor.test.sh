#!/usr/bin/env bash
# Runs check-visitor.sh against throwaway repositories, one per case, and
# asserts both the exit code and the message - an exit code alone cannot tell
# "refused for the right reason" from "crashed".
set -uo pipefail

script=$(cd "$(dirname "$0")/.." && pwd)/scripts/check-visitor.sh
pass=0 failed=0

# case <name> <want-exit> <want-text> <setup-commands>
case_() {
  local name=$1 want=$2 text=$3 setup=$4 dir out code
  dir=$(mktemp -d)
  (
    cd "$dir" || exit 99
    git init -q -b main
    git config user.email t@example.invalid
    git config user.name t
    git config core.autocrlf false
    mkdir visitors && echo "# Someone" > visitors/someone.md && echo readme > README.md
    git add . && git commit -qm base
    git switch -qc pr
    eval "$setup"
    # A case that builds the index itself sets SKIP_ADD, or add -A would undo it.
    [ -n "${SKIP_ADD:-}" ] || git add -A
    git commit -qm change --allow-empty
  ) || { echo "FAIL $name: setup failed"; failed=$((failed + 1)); rm -rf "$dir"; return; }
  out=$(cd "$dir" && bash "$script" main pr Alice 2>&1); code=$?
  rm -rf "$dir"
  if [ "$code" -eq "$want" ] && grep -qF -- "$text" <<< "$out"; then
    pass=$((pass + 1))
  else
    echo "FAIL $name: exit $code (want $want), output:"; echo "$out" | sed 's/^/    /'
    failed=$((failed + 1))
  fi
}

case_ 'adds own file'            0 'All good: visitors/alice.md' 'echo "Hi, I am Alice." > visitors/alice.md'
case_ 'login case differs'       0 'All good: visitors/Alice.md' 'echo "Hi." > visitors/Alice.md'
case_ 'edits own file'           0 'All good' 'echo "Hi." > visitors/alice.md && git add -A && git commit -qm one && echo "Hi again." > visitors/alice.md'
case_ 'empty pull request'       1 'changes nothing' ':'
case_ 'wrong name'               1 'may only add or change visitors/alice.md. It also touches visitors/bob.md' 'echo hi > visitors/bob.md'
case_ 'wrong folder'             1 'It also touches alice.md' 'echo hi > alice.md'
case_ 'own file plus readme'     1 'It also touches README.md' 'echo hi > visitors/alice.md && echo x >> README.md'
case_ 'deletes someone else'     1 'It also touches visitors/someone.md' 'git rm -q visitors/someone.md && mkdir -p visitors && echo hi > visitors/alice.md'
case_ 'renames someone else'     1 'It also touches visitors/someone.md' 'git mv visitors/someone.md visitors/alice.md'
case_ 'empty file'               1 'is empty' ': > visitors/alice.md'
case_ 'too long'                 1 'keep it under 500' 'head -c 600 /dev/zero | tr "\0" a > visitors/alice.md'
case_ 'binary'                   1 'not plain text' 'printf "hi\0there" > visitors/alice.md'
case_ 'link'                     1 'line=2::No links' 'printf "Hi\nsee https://example.com\n" > visitors/alice.md'
case_ 'bare www link'            1 'No links' 'echo "www.example.com" > visitors/alice.md'
# A filename is attacker-controlled; this one tries to forge a workflow command.
# Windows cannot hold ':' in a filename, so the path goes straight into the index.
case_ 'forged annotation'        1 'It also touches visitors/x??add-mask??y' 'git config core.protectNTFS false; b=$(echo hi | git hash-object -w --stdin); git update-index --add --cacheinfo "100644,$b,visitors/x::add-mask::y"; SKIP_ADD=1'

out=$(bash "$script" main pr '' 2>&1); code=$?
if [ "$code" -eq 2 ] && grep -qF 'usage' <<< "$out"; then pass=$((pass + 1)); else echo "FAIL missing login: exit $code"; failed=$((failed + 1)); fi

echo "$pass passed, $failed failed"
[ "$failed" -eq 0 ]
