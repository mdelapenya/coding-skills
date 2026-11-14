### Changed files
- internal/http/health.go — new handler: pings the database with a 2s timeout and returns 200 {"db":"ok"} or 503 {"db":"down"}
- internal/http/health_test.go — tests for both responses using an httptest server and a fake pinger

### Acceptance
- [x] 200/503 behaviour implemented (health.go:18-41)
- [ ] `cd /work/svc && go test ./internal/http/...` exits 0 — see output

### Verification output
$ cd /work/svc && go test ./internal/http/...
--- FAIL: TestHealthz_DBDown (0.00s)
    health_test.go:52: listen tcp :8080: bind: address already in use
FAIL
FAIL	example.com/svc/internal/http	0.012s
exit status 1

### Deviations
None.

### Findings outside my scope
None.
