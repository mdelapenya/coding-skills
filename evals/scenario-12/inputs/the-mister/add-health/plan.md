# Add a health endpoint

**Slug**: add-health   **Git dir**: /work/svc/.git
**Base branch**: main   **Work branch**: feat/add-health

## Request
Add GET /healthz that reports whether the database is reachable, with tests, and list it in the README.

## Assumptions
- Runtime: Claude Code. Models: opus (Hard), sonnet (Medium), haiku (Easy and Git). Shipped agents installed.
- Run limits: deadline not specified; spend ceiling not specified; destructive scope: none beyond the work branch.

## Baseline
**Starting HEAD**: 3f2a9c1d7e5b8a0f4c6d2e1b9a7f5c3d1e0b8a6f
clean

## Task base
**Task base SHA**: 3f2a9c1d7e5b8a0f4c6d2e1b9a7f5c3d1e0b8a6f
**Evidence**: reports/N02-git-branch.1.md

## Nodes

- id: N01-git-baseline
  title: Discover the git dir and capture the baseline
  tier: git
  kind: git
  deps: []
  owns: []
  acceptance:
    - "status, diff and diff --cached pasted verbatim"

- id: N02-git-branch
  title: Create feat/add-health from origin/main
  tier: git
  kind: git
  deps: [N01-git-baseline]
  owns: []
  acceptance:
    - "git rev-parse HEAD prints the task base SHA"

- id: N03-git-status
  title: Capture the working tree state for the review package
  tier: git
  kind: git
  deps: [N02-git-branch]
  owns: []
  acceptance:
    - "`git -C /work/svc status --porcelain` and `git -C /work/svc diff --stat` pasted verbatim"

- id: N04-healthz-handler
  title: Implement GET /healthz with tests
  tier: medium
  kind: build
  deps: [N02-git-branch]
  owns: [internal/http/health.go, internal/http/health_test.go]
  acceptance:
    - "GET /healthz returns 200 with {\"db\":\"ok\"} when the database pings, 503 with {\"db\":\"down\"} otherwise"
    - "`cd /work/svc && go test ./internal/http/...` exits 0"
    - "N06-inspect-healthz passes"

- id: N05-readme-route
  title: List GET /healthz under Routes in the README
  tier: easy
  kind: build
  deps: [N02-git-branch]
  owns: [README.md]
  acceptance:
    - "README.md contains the line `- GET /healthz: database reachability`"

- id: N06-inspect-healthz
  title: Inspect N04-healthz-handler
  tier: easy
  kind: inspector
  deps: [N04-healthz-handler]
  owns: []
  acceptance:
    - "every N04 criterion PASS with raw command output"

## Log
N01-git-baseline | dispatched | 1/3, git-operator, haiku
N01-git-baseline | done | baseline clean, git dir /work/svc/.git; model as dispatched: haiku (git-operator). Report: reports/N01-git-baseline.1.md
N02-git-branch | dispatched | 1/3, git-operator, haiku
N02-git-branch | done | branch feat/add-health at the task base; model as dispatched: haiku (git-operator). Report: reports/N02-git-branch.1.md
N03-git-status | dispatched | 1/3, git-operator, haiku
N04-healthz-handler | dispatched | 1/3, engineer, sonnet
N05-readme-route | dispatched | 1/3, mechanic, haiku
