# Plan the User Activity Endpoint

## Background

Your team coordinates engineering work using a planning system called **the-mister**. When a feature is approved, the engineering lead writes a `plan.md` decomposing the work into discrete nodes that independent workers can pick up and execute. Each node has a tier (which determines who works on it), a list of files it owns, and explicit acceptance criteria. The plan also maintains a Log of all node state transitions.

A product manager has filed a feature request (see `inputs/request.md`) for the User Service, a small Go web service. The current service source code is in `inputs/`. You can inspect it to understand the existing structure before planning.

## Your Task

Acting as the engineering lead, write a complete the-mister plan for implementing the feature described in `inputs/request.md`. The plan has been approved in this conversation, so write it now; the slug is `add-user-activity`.

The service's repository is checked out at `/work/user-service`, and its git dir is `/work/user-service/.git`; use those paths in every command the plan contains. That checkout is not available in this sandbox, so write the plan to `./the-mister/add-user-activity/plan.md` in your working directory, exactly as you would write it under the git dir. Do not run `git init` or create a `.git` directory here.

## Expected Output

A single file, `./the-mister/add-user-activity/plan.md`, containing the complete plan. The plan should break the feature into all the work needed — source code, tests, database layer, documentation, and version control operations — in a form that independent workers can execute without further clarification.
