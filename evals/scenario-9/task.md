# Write Work Orders for the LRU Cache Plan

## Background

The userdb service team has an approved plan to add an LRU caching layer to their user lookup service. You are acting as the mister for this task, responsible for authoring the work orders that instruct each worker on what to do.

The approved plan is at `inputs/plan-stub.md`. It describes four nodes that need work orders. Additional feature context — including the target repository location, module name, file structure, and desired cache API — is in `inputs/task-description.txt`. Representative source files from the repository are under `inputs/repo/` for reference.

## Work Orders to Write

Write one order file for each node in the plan. Place them under `orders/` in your current working directory:

- `orders/N01-baseline.md`
- `orders/N02-cache.md`
- `orders/N03-tests.md`
- `orders/N04-commit.md`

Each order must give the assigned worker everything they need to carry out their node. Use the git directory specified in the plan for any shell or git commands you include in the orders.
