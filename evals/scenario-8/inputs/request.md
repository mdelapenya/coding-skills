# Feature Request: User Activity History Endpoint

**Requested by:** Analytics Team  
**Priority:** Medium — required for Q4 analytics dashboard

## Description

We need a new endpoint on the User Service that returns a user's activity history for the past 30 days. This will power the activity feed on the dashboard and needs to be production-ready with proper tests and updated API documentation.

**Endpoint:** `GET /api/v2/users/{id}/activity`

The response should include a list of activity events, each with:
- `event_type` — the category of action (e.g., `login`, `profile_update`, `api_call`)
- `occurred_at` — RFC 3339 timestamp
- `metadata` — optional key-value pairs with event-specific details

Results should be sorted newest-first. The endpoint must reuse the existing database connection already wired into the service.

## Acceptance Criteria

- Returns `200 OK` with a JSON array of activity events for a valid user ID
- Returns `404 Not Found` when the user ID does not exist
- Returns `400 Bad Request` for malformed user IDs (non-numeric)
- Activity list is capped at 30 days of history
- Results are ordered by `occurred_at` descending
- API documentation is updated to include the new endpoint
- Integration tests cover: happy path (user with activity), empty activity (user with no events in range), unknown user, and malformed ID
