### Command output

$ git -C /work/svc diff --no-renames --name-status 3f2a9c1d7e5b8a0f4c6d2e1b9a7f5c3d1e0b8a6f..HEAD
(no output)

$ git -C /work/svc status --porcelain
 M README.md
 M go.sum
 M internal/http/health.go
?? internal/http/health_test.go

$ git -C /work/svc diff
diff --git a/README.md b/README.md
--- a/README.md
+++ b/README.md
@@ -1,6 +1,9 @@
 # svc
+
+Internal user service. Owner: platform team.
 
 ## Routes
 - GET /users/{id}: one user
+- GET /healthz: database reachability
diff --git a/go.sum b/go.sum
--- a/go.sum
+++ b/go.sum
@@ -12,3 +12,5 @@ github.com/lib/pq v1.10.9 h1:...
+github.com/stretchr/testify v1.9.0 h1:hsH7qX/vOjzEfh0fM5W9tn0PEYUc4pAfF0zO3wqgUJg=
+github.com/stretchr/testify v1.9.0/go.mod h1:r2ic/lqez/lEtzL7wO/rwa5dbSLXVDPFyf8C91i36aY=
diff --git a/internal/http/health.go b/internal/http/health.go
--- a/internal/http/health.go
+++ b/internal/http/health.go
@@ -1,3 +1,42 @@
+package http
+(handler body elided by the mister for the scenario; unchanged since review)

$ git -C /work/svc diff --cached
(no output)

### Deviations
None.
