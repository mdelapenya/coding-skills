# The image the Slack scripts run in when a member runs on a host (not in a
# Docker Sandbox, whose image already has curl and jq). Published as
# docker.io/mdelapenya/coordinating-agents-slack. It holds only curl and jq:
# the scripts are bind-mounted read-only at run time, so what runs is what
# you read in this directory, and the token arrives only through --env-file.
FROM alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f
# apk upgrade pulls the fixes Alpine publishes before the base image is
# rebuilt (zlib for CVE-2026-4738 in 1.0.2); the release workflow's CVE scan
# gates every build.
RUN apk upgrade --no-cache && apk add --no-cache curl jq
LABEL org.opencontainers.image.title="coordinating-agents-slack" \
      org.opencontainers.image.description="curl and jq for the coordinating-agents Slack scripts" \
      org.opencontainers.image.source="https://github.com/mdelapenya/coding-skills/tree/main/skills/coordinating-agents/scripts/slack" \
      org.opencontainers.image.licenses="MIT"
USER nobody
