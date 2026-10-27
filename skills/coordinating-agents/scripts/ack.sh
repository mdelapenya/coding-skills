#!/bin/sh
# ack.sh <channel> <me> <item>...
# Records items as read in <me>.cursor (written only by <me>). Items are what
# watch.sh printed: a message name (astra-003.md) or a marker (astra.done).
# Each item must exist. Messages are acknowledged in order per sender: acking
# astra-003.md requires astra-002.md to be acked already or earlier in the
# same call, so a typo or a skipped message can never hide later ones. The
# cursor only moves forward and is replaced atomically.
set -eu
[ $# -ge 3 ] || { echo "usage: ack.sh <channel> <me> <item>..." >&2; exit 2; }
d=$1 me=$2; shift 2
cursor="$d/$me.cursor"
work="$d/.cursor.$me.$$"
touch "$cursor"
cp "$cursor" "$work"
trap 'rm -f "$work" "$work.new"' EXIT

seen() { awk -v k="$1" '$1==k && $2+0>m {m=$2+0} END {print m+0}' "$work"; }

for item in "$@"; do
  [ -e "$d/$item" ] || { echo "no such item in channel: $item" >&2; exit 1; }
  case $item in
    "$me"-*|"$me".*) echo "not acking your own item: $item" >&2; exit 1 ;;
    *-[0-9][0-9][0-9].md)
      who=${item%-*}; n=${item##*-}; n=$(expr "${n%.md}" + 0)
      last=$(seen "$who")
      if [ "$n" -le "$last" ]; then echo "already acked $item"; continue; fi
      if [ "$n" -ne $((last + 1)) ]; then
        echo "gap: ack $(printf '%s-%03d.md' "$who" $((last + 1))) first" >&2; exit 1
      fi
      echo "$who $n" >> "$work" ;;
    *.done|*.blocked)
      echo "marker:$item 1" >> "$work" ;;
    *) echo "not a message or marker: $item" >&2; exit 1 ;;
  esac
  echo "acked $item"
done
# Compact to one line per key (the highest value), then swap in atomically.
awk '{ if (!($1 in m) || $2+0 > m[$1]) m[$1]=$2+0 } END { for (k in m) print k, m[k] }' "$work" | sort > "$work.new"
mv "$work.new" "$cursor"
