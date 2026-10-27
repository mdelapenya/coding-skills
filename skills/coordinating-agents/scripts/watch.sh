#!/bin/sh
# watch.sh <channel> <me> [timeout-seconds] [interval-seconds]
# Polls the channel until something unread from another member appears,
# then prints one line per item and exits 0:
#   new <member>-NNN.md      a message beyond <me>'s cursor for that member
#   marker <member>.done     a terminal marker not yet acknowledged
#   marker <member>.blocked
# Exits 3 with "timeout" when nothing arrives in time (default 600 s, poll
# every 30 s). A timeout means only that nothing arrived. Reads only.
set -u
[ $# -ge 2 ] || { echo "usage: watch.sh <channel> <me> [timeout] [interval]" >&2; exit 2; }
d=$1 me=$2 timeout=${3:-600} interval=${4:-30}
cursor="$d/$me.cursor"
start=$(date +%s)

seen() { # highest acknowledged value for a key, 0 if none
  [ -f "$cursor" ] || { echo 0; return; }
  awk -v k="$1" '$1==k && $2+0>m {m=$2+0} END {print m+0}' "$cursor"
}

scan() {
  for f in "$d"/*-[0-9][0-9][0-9].md; do
    [ -e "$f" ] || continue
    b=${f##*/}; who=${b%-*}
    [ "$who" = "$me" ] && continue
    n=${b##*-}; n=$(expr "${n%.md}" + 0)
    [ "$n" -gt "$(seen "$who")" ] && echo "new $b"
  done
  for f in "$d"/*.done "$d"/*.blocked; do
    [ -e "$f" ] || continue
    b=${f##*/}; who=${b%.*}
    [ "$who" = "$me" ] && continue
    [ "$(seen "marker:$b")" = "1" ] || echo "marker $b"
  done
}

while :; do
  out=$(scan)
  if [ -n "$out" ]; then echo "$out"; exit 0; fi
  if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then echo "timeout"; exit 3; fi
  sleep "$interval"
done
