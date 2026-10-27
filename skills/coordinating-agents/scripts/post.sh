#!/bin/sh
# post.sh <channel> <me> <draft>
# Publishes <draft> as the next <me>-NNN.md (001-999). The copy goes to a
# hidden temp name first and is then hard-linked into place, so a watcher
# never reads a half-written message and an existing message is never
# overwritten: ln fails if the name exists. Only <me> writes <me>-*.md.
set -eu
[ $# -eq 3 ] || { echo "usage: post.sh <channel> <me> <draft>" >&2; exit 2; }
d=$1 me=$2 draft=$3
[ -d "$d" ] || { echo "no channel at $d" >&2; exit 1; }
[ -f "$draft" ] || { echo "no draft at $draft" >&2; exit 1; }
last=0
for f in "$d/$me"-[0-9][0-9][0-9].md; do
  [ -e "$f" ] || continue
  n=${f##*-}; n=$(expr "${n%.md}" + 0)
  [ "$n" -gt "$last" ] && last=$n
done
next=$((last + 1))
[ "$next" -le 999 ] || { echo "message numbers exhausted for $me (999)" >&2; exit 1; }
name=$(printf '%s-%03d.md' "$me" "$next")
tmp="$d/.tmp.$me.$$"
cp "$draft" "$tmp"
if ln "$tmp" "$d/$name" 2>/dev/null; then
  rm -f "$tmp"
  echo "posted $name"
else
  rm -f "$tmp"
  echo "refusing to overwrite $name" >&2
  exit 1
fi
