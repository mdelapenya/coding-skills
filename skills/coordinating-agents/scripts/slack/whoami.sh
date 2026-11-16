#!/bin/sh
# whoami.sh: prints the bot user id, bot name, and workspace behind this
# member's token (auth.test). The initiator needs every member's id for the
# README's members: line; run this first in each member's session. It also
# proves the token reaches Slack (in a sandbox: that the sbx secret and its
# proxy substitution work). Prints no secret.
set -eu
. "$(dirname "$0")/lib.sh"
r=$(api auth.test) || die "auth.test failed: $(printf '%s' "$r" | jq -r '.error // "unknown"')"
printf '%s' "$r" | jq -r '"bot \(.user_id) name=\(.user) team=\(.team) url=\(.url)"'
