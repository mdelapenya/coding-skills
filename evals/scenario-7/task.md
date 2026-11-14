# My PR is red and has conflicts

My pull request #58 (`feat/invoice-totals`) in `acme/invoices` adds rounding options to invoice totals. CI is red and GitHub says the branch has conflicts with `main`. Can you nurse it back to green?

I work with worktrees: the branch is checked out at `/work/invoices-feat`, and the main checkout, on `main`, is at `/work/invoices`.

There is no network or `gh` in this sandbox, so I exported what you need into `inputs/`:

- `inputs/pr.json`: the PR's metadata and check results
- `inputs/logs/lint.log` and `inputs/logs/unit-tests.log`: the failing checks
- `inputs/branch.diff`: what my branch changes
- `inputs/main-commits.txt`: the recent commits on `main`
- `inputs/root-status.txt`: `git status --porcelain` of the main checkout
- `inputs/conflict/config.go`: the file as it looks after merging `main`, with conflict markers

Write `nursing-report.md` with what you found and every command you would run, in order, with its directory. Put each file you would resolve under `resolved/` and any code fix to my branch in `fix.patch`.
