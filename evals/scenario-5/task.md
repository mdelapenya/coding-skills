# Did my PR break CI?

CI went red on my PR (`feature/checkout-refactor`, a cleanup of the cart calculation in our storefront service): three tests fail. Before I ask for review I need to know which of those failures are my fault and which were already broken.

This sandbox has no network or `gh`, so I dumped what I could from GitHub Actions into `inputs/`:

- `inputs/pr-run.json`: my PR's failing run, with each failing test and its error output
- `inputs/other-runs.json`: the latest completed runs of the same workflow on other branches
- `inputs/pr.diff`: my PR's diff

Write what you find to `ci-report.md` in the working directory.
