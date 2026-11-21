#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
msg() { printf '%s\n' '---' "from: $2" "to: $3" "re: $4" "kind: $5" "expects: $6" '---' body > "$d/$1.md"; }
watch() { sh "$root/skills/coordinating-agents/scripts/watch.sh" "$d" beta 0 1 || [ "$?" = 3 ]; }
msg alpha-001 alpha all '' request reply
printf 'alpha 1\n' > "$d/beta.cursor"
out=$(watch)
printf '%s\n' "$out" | grep -q '^pending alpha-001.md$'
printf '%s\n' "$out" | grep -q '^timeout$'
msg beta-001 beta gamma alpha-001 reply none
out=$(watch)
printf '%s\n' "$out" | grep -q '^pending alpha-001.md$'
msg beta-002 beta alpha alpha-001 reply none
out=$(watch)
if printf '%s\n' "$out" | grep -q '^pending '; then exit 1; fi
msg alpha-002 alpha all '' request reply
msg gamma-001 beta alpha alpha-002 reply none
msg gamma-002 alpha beta alpha-002 status none
out=$(watch)
printf '%s\n' "$out" | grep -q '^pending alpha-002.md$'
printf '%s\n' "$out" | grep -q '^new gamma-001.md$'
sh "$root/skills/coordinating-agents/scripts/ack.sh" "$d" beta gamma-001.md gamma-002.md >/dev/null
msg alpha-003 alpha gamma alpha-002 status none
out=$(watch)
printf '%s\n' "$out" | grep -q '^pending alpha-002.md$'
msg alpha-004 alpha beta alpha-002 status none
out=$(watch)
if printf '%s\n' "$out" | grep -q '^pending '; then exit 1; fi
echo 'disk pending checks passed'
