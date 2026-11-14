# Add a health endpoint

**Slug**: add-health   **Git dir**: /work/svc/.git
**Base branch**: main   **Work branch**: current

## Request
Add GET /healthz that reports whether the database is reachable, with tests, and list it in the README. Work on the current branch and commit it; do not push.

## Assumptions
- Runtime: Claude Code. Models: opus (Hard), sonnet (Medium), haiku (Easy and Git). Shipped agents installed.
- Implementing models for trailers: sonnet (N03), haiku (N04).
- Run limits: not specified. Dependencies: none may be added.

## Baseline
**Starting HEAD**: 3f2a9c1d7e5b8a0f4c6d2e1b9a7f5c3d1e0b8a6f
```
 M README.md
```
`git diff` of README.md at baseline (the user's own edit, protected):
```
@@ -1,4 +1,6 @@
 # svc
+
+Internal user service. Owner: platform team.
 
 ## Routes
```

## Task base
**Task base SHA**: 3f2a9c1d7e5b8a0f4c6d2e1b9a7f5c3d1e0b8a6f
**Evidence**: reports/N01-git-baseline.1.md

## Nodes

- id: N01-git-baseline
  title: Discover the git dir, capture the baseline and the task base
  tier: git
  kind: git
  deps: []
  owns: []
  acceptance:
    - "status, diff and diff --cached pasted verbatim"

- id: N03-healthz-handler
  title: Implement GET /healthz with tests
  tier: medium
  kind: build
  deps: [N01-git-baseline]
  owns: [internal/http/health.go, internal/http/health_test.go]
  acceptance:
    - "`cd /work/svc && go test ./internal/http/...` exits 0"

- id: N04-readme-route
  title: List GET /healthz under Routes in the README
  tier: easy
  kind: build
  deps: [N01-git-baseline]
  owns: [README.md]
  acceptance:
    - "README.md contains `- GET /healthz: database reachability`, and the baseline hunk at lines 2-3 is preserved"

- id: N06-review
  title: Independent review of the assembled change
  tier: hard
  kind: review
  deps: [N03-healthz-handler, N04-readme-route]
  owns: []
  acceptance:
    - "no unresolved confirmed finding"

- id: N07-git-preflight
  title: Preflight before staging
  tier: git
  kind: git
  deps: [N06-review]
  owns: []
  acceptance:
    - "every changed path is owned and no baseline change is at risk"

## Review
Round 1: manifests/N06-review.md (SHA-256 5b1e0c3a9f7d2b4e6a8c0d1f3e5a7b9c2d4f6e8a0b1c3d5e7f9a2b4c6d8e0f1a), reviewer opus, no confirmed findings; review converged.

## Log
N01-git-baseline | dispatched | 1/3, git-operator, haiku
N01-git-baseline | done | baseline has the user's README.md edit; task base recorded. Report: reports/N01-git-baseline.1.md
N03-healthz-handler | dispatched | 1/3, engineer, sonnet
N04-readme-route | dispatched | 1/3, mechanic, haiku
N03-healthz-handler | done | tests pass (exit 0); inspection N05 PASS; model as dispatched: sonnet (engineer). Report: reports/N03-healthz-handler.1.md
N04-readme-route | done | route line present and baseline hunk preserved; model as dispatched: haiku (mechanic). Report: reports/N04-readme-route.1.md
N06-review | dispatched | 1/3, reviewer, opus
N06-review | done | round 1 converged with no confirmed findings. Report: reports/N06-review.1.md
N07-git-preflight | dispatched | 1/3, git-operator, haiku
