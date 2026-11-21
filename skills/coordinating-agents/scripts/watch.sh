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

# Pending obligations are derived from the immutable messages, independently
# of the read cursor. A status from the sender addressed to us withdraws one.
pending() {
  awk -v me="$me" '
    FNR == 1 { file=FILENAME; sub(/^.*\//, "", file); sub(/\.md$/, "", file); owner=file; sub(/-[0-9][0-9][0-9]$/, "", owner); to=re=kind=expects=""; fm=0 }
    FNR == 1 && $0 == "---" { fm=1; next }
    fm && $0 == "---" { fm=0; next }
    fm { line=$0; sub(/[ \t]+#.*/, "", line); split(line, a, ":"); v=a[2]; gsub(/^[ \t]+|[ \t]+$/, "", v); if (a[1]=="to") to=v; if (a[1]=="re") re=v; if (a[1]=="kind") kind=v; if (a[1]=="expects") expects=v }
    { ids[file]=1; sender[file]=owner; dest[file]=to; ref[file]=re; type[file]=kind; expectation[file]=expects }
    END {
      for (id in ids) if (sender[id] != me && (dest[id] == me || dest[id] == "all") && expectation[id] == "reply") {
        closed=0
        for (r in ids) { target=ref[r]; sub(/\.md$/, "", target); if (target != id) continue
          if (sender[r] == me && (dest[r] == sender[id] || dest[r] == "all")) closed=1
          if (sender[r] == sender[id] && dest[r] == me && type[r] == "status") closed=1
        }
        if (!closed) print "pending " id ".md"
      }
    }' "$d"/*-[0-9][0-9][0-9].md 2>/dev/null | sort
}

while :; do
  out=$(scan)
  if [ -n "$out" ]; then echo "$out"; pending; exit 0; fi
  if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then echo "timeout"; pending; exit 3; fi
  sleep "$interval"
done
