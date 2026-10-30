# Curious Pandas practice repo

A safe place to open your first real pull request. It is the hands-on half of
the [Working with others](https://learn.curiouspandas.dev/learn/git/collaborate/)
lesson on [Curious Pandas](https://learn.curiouspandas.dev). Nothing you do here
can break anything, and nobody minds a red check.

## The exercise

1. **Fork** this repository (the Fork button, top right). You now have your own
   copy at `github.com/<you>/practice`.
2. **Clone your fork** and make a branch:
   ```bash
   git clone https://github.com/<you>/practice.git
   cd practice
   git switch -c hello
   ```
3. **Add one file**, named after your GitHub username, in `visitors/`:
   ```bash
   echo "Hi, I'm learning git with Curious Pandas." > visitors/<you>.md
   git add visitors/<you>.md
   git commit -m "docs: add <you> to visitors"
   git push -u origin hello
   ```
4. **Open a pull request.** GitHub shows a "Compare & pull request" button on
   your fork. Point it at `CuriousPandas/practice` `main`.
5. **Watch the checks.** The `visitor-file` check runs on your pull request.
   Green means it follows the rules. Red tells you exactly what to fix - fix it
   on the same branch, `git push` again, and the check re-runs by itself. That
   loop is most of what working on a team feels like.

The rules the check enforces:

- Change only `visitors/<your-username>.md` (any letter case).
- Keep it under 500 bytes of plain text.
- No links.

## What happens next

`main` is protected: a pull request needs the green check **and** a
maintainer's approval to merge. Some pull requests get merged; most are closed
after 14 days by a scheduled job. Neither one means you did it wrong. You have
already done the real thing.

Please keep it kind, and don't post anything about yourself you would not put
on a public website - this repository is public.

## For maintainers

| File | What it does |
|---|---|
| `scripts/check-visitor.sh` | The rules above. Runs from `main`, so a pull request can't change its own check. |
| `tests/check-visitor.test.sh` | 16 cases, each asserting the exit code *and* the reason. Run with `bash tests/check-visitor.test.sh`. |
| `.github/workflows/check.yml` | Runs the check on every pull request with a read-only token (`pull_request`, never `pull_request_target`). |
| `.github/workflows/tidy.yml` | Weekly: closes practice pull requests older than 14 days. Label one `keep-open` to exempt it. |
| `scripts/configure-repo.sh` | The repository's GitHub settings, ruleset and fork-approval policy. Change settings there and re-run it, not in the web UI. |

The check is for teaching, not security: a pull request's own copy of the
workflow file runs, so a determined author can make it pass. The required
review is the boundary.

## License

MIT, copyright [Sallux](https://sallux.dev). See [LICENSE](LICENSE).
