## What's changed

After profiling production traffic, we found that user profile lookups are our most expensive repeated queries — the same user IDs are fetched dozens of times per session with no caching. This PR introduces a Redis-backed response cache for the `/api/users/<id>` endpoint that short-circuits Postgres queries on repeated lookups, cutting average latency from ~45ms to ~2ms on cache hits.

## Why is this important?

User profile endpoints account for roughly 40% of total API calls during peak hours. The database was under sustained heavy read load with no mitigation. Caching reduces that load significantly and improves response times for all users simultaneously.

## Changes

- Added `src/cache/redis_client.py` with `cache_get` / `cache_set` helpers
- Modified `src/api/users.py` to check cache before querying the database
- Added `tests/cache/test_redis_client.py` with unit tests for all cache behaviors
- Added `redis==5.0.1` to `requirements.txt`

## Test plan

Run `pytest tests/cache/` to execute the new unit tests. For a manual smoke test, hit the `/api/users/<id>` endpoint twice and check that the second request logs `cache:hit`.

## Deployment notes

Before deploying to production, ensure a Redis instance is running and accessible. Set the `REDIS_URL` environment variable (e.g., `redis://your-redis-host:6379/0`). The cache TTL defaults to 300 seconds and can be adjusted via the `CACHE_TTL_SECONDS` environment variable if needed. No database migrations are required.
