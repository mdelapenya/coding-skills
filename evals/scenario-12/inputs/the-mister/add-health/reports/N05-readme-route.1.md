### Changed files
- /work/svc/docs/README.md — added `- GET /healthz: database reachability` under `## Routes`

### Acceptance
- [x] README contains the line `- GET /healthz: database reachability`

### Verification output
$ grep -n 'healthz' /work/svc/docs/README.md
14:- GET /healthz: database reachability

### Deviations
None.
