# Plan the User Activity Endpoint

## Background

Your team coordinates engineering work using a planning system called **the-mister**. When a feature is approved, the engineering lead writes a `plan.md` decomposing the work into discrete nodes that independent workers can pick up and execute. Each node has a tier (which determines who works on it), a list of files it owns, and explicit acceptance criteria. The plan also maintains a Log of all node state transitions.

A product manager has filed a feature request (see `inputs/request.md`) for the User Service, a small Go web service. The current service source code is in `inputs/`. You can inspect it to understand the existing structure before planning.

## Your Task

Initialize a git repository in your working directory if one does not already exist. Then, acting as the engineering lead, write a complete the-mister plan for implementing the feature described in `inputs/request.md`.

The plan must be written to:

```
<git-dir>/the-mister/add-user-activity/plan.md
```

where `<git-dir>` is the absolute path returned by:

```
git rev-parse --path-format=absolute --git-common-dir
```

For a freshly initialized repository this will be `.git`, so the plan goes to `.git/the-mister/add-user-activity/plan.md`.

## Expected Output

A single file at the path above containing the complete plan. The plan should break the feature into all the work needed — source code, tests, database layer, documentation, and version control operations — in a form that independent workers can execute without further clarification.
