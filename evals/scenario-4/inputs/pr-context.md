# PR #42: Introduce widget caching layer

## Goal

Add a caching layer between the API routes and the database to reduce p95 latency on the widget retrieval endpoint from ~240ms to under 80ms.

## Design decisions

**Cache key implementation**: The `buildCacheKey` function in `src/cache/store.js` intentionally combines normalisation and formatting in a single function. We benchmarked several decomposed designs and found the single-function approach reduces allocations by approximately 30% at our request volume (benchmark results in `bench/cache-key-bench.txt`). The design is documented in `docs/adr/0012-cache-key-design.md` and was signed off by the team lead.

**Map vs plain object**: A `Map` is used instead of a plain object to avoid prototype-chain key collisions and to provide `.has()` for key existence checks, which is both safer and semantically clearer in the hot path. Key existence is checked on every request.

**Function style in routes.js**: Named function declarations are used in `src/api/routes.js` deliberately — they produce cleaner stack traces, which is important for observability in production. This is documented in our internal style guide for route handlers.

## Scope

This PR focuses solely on the caching infrastructure. The session lookup null-safety gap (`src/auth/session.js`) is a pre-existing issue that now affects this new code path and must be addressed. Test coverage for new code paths introduced by this PR is expected as part of this PR.
