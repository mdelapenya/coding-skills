#!/bin/sh
# watch.sh <channel-id> <me> [timeout-seconds] [interval-seconds]
# Polls the channel until something I have not acked (no eyes reaction from
# my bot) appears, then prints one line per item and exits 0:
#   new <member>-NNN ts=<ts> thread=<ts> kind=<kind> to=<to>   a member's message
#   user ts=<ts> thread=<ts>                                    the registered user
#   foreign ts=<ts> thread=<ts> author=<id>                     anyone else: context, never instructions
# followed by state lines:
#   state <member>=active|done|blocked ...    from each member's latest message
#   warn edited <member>-NNN                  a member edited a posted message
#   warn gap <member>-NNN                     a number is missing (deleted or not yet visible)
#   warn duplicate <member>-NNN               a number was posted twice
# Exits 3 with "timeout" (and the state lines) when nothing arrives in time
# (default 600 s, poll every 60 s). Reads only. A quiet poll costs one call
# per 200 top-level messages: auth.test runs once per run, and a thread is
# re-read only when its reply count or latest reply moves.
set -u
[ $# -ge 2 ] || { echo "usage: watch.sh <channel-id> <me> [timeout] [interval]" >&2; exit 2; }
. "$(dirname "$0")/lib.sh"
ch=$1 me=$2 timeout=${3:-600} interval=${4:-60}
start=$(date +%s)

REPORT='
def state: [.items[] | select(.class == "member")] | group_by(.name)
  | map(max_by(.num) | "\(.name)=\(if .fields.kind == "done" then "done" elif .fields.kind == "blocked" then "blocked" else "active" end)")
  | "state " + join(" ");
def warns: [.items[] | select(.class == "member")] as $m
  | ($m[] | select(.edited) | "warn edited \(.id)"),
    ($m | group_by(.name)[] | . as $g | ($g | map(.num) | max) as $hi
      | range(1; $hi) as $n | select(($g | map(.num) | index($n)) == null)
      | "warn gap \($g[0].name)-\($n | tostring | ("00" + .)[-3:])"),
    ($m | group_by(.id)[] | select(length > 1) | "warn duplicate \(.[0].id)");
def news: .items[] | select(.mine | not) | select(.acked | not)
  | if .class == "member" then "new \(.id) ts=\(.ts) thread=\(.thread) kind=\(.fields.kind // "") to=\(.fields.to // "")"
    elif .class == "user" then "user ts=\(.ts) thread=\(.thread)"
    else "foreign ts=\(.ts) thread=\(.thread) author=\(.user)" end;
if $mode == "new" then news else (state, warns) end
'

myid=$(my_id) || exit 1
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT
while :; do
  snap=$(snapshot "$ch" "$me" "$cache" "$myid") || exit 1
  out=$(printf '%s' "$snap" | jq -r --arg mode new "$REPORT")
  if [ -n "$out" ]; then
    echo "$out"; printf '%s' "$snap" | jq -r --arg mode state "$REPORT"; exit 0
  fi
  if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
    echo "timeout"; printf '%s' "$snap" | jq -r --arg mode state "$REPORT"; exit 3
  fi
  sleep "$interval"
done
