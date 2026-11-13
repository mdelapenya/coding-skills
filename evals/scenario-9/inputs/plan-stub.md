# Plan: add-lru-cache

**Slug:** add-lru-cache
**Git-dir:** /home/dev/projects/userdb
**State directory:** /home/dev/projects/userdb/the-mister/add-lru-cache/
**Branch:** feature/lru-cache

## Goal

Reduce repeated database lookups in the user lookup service by adding an in-process LRU cache with configurable capacity and TTL.

## Nodes

### N01 — Baseline capture
**Tier:** Git
**Owns:** (read-only)
**Goal:** Record the current branch, git status, and test suite baseline before any changes begin.

### N02 — Implement LRU cache package
**Tier:** Hard
**Owns:** `internal/cache/`
**Goal:** Create the LRU cache package and integrate it with the user lookup service.
**Acceptance:** Cache correctly serves user objects; hits avoid database calls; misses populate the cache; TTL and capacity eviction work correctly; `go test ./...` passes with `-race`.

### N03 — Integration tests for cache layer
**Tier:** Medium
**Owns:** `internal/cache/`
**Goal:** Write integration tests covering the main cache scenarios.
**Acceptance:** Tests cover cache hit, cache miss, TTL expiry, and eviction; all pass; concurrent access is safe.

### N04 — Stage and commit
**Tier:** Git
**Owns:** (write)
**Goal:** Stage all new and modified files under `internal/cache/` and in `internal/users/lookup.go`, then commit using the prepared commit message.
