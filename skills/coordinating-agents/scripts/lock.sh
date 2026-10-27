#!/bin/sh
# lock.sh acquire <channel> <me> [timeout-seconds]   prints a token
# lock.sh release <channel> <me> <token>
# lock.sh show    <channel>
# An mkdir lock for edits to a file more than one member writes (a shared
# plan with owned sections). Messages never need it. Hold it for one edit,
# never while waiting for a person or another member. Release needs the
# token acquire printed, not just the name. A lock is never broken by age:
# `show` prints the owner and the time so the user can decide.
set -eu
[ $# -ge 2 ] || { echo "usage: lock.sh acquire|release|show <channel> [<me> [timeout|token]]" >&2; exit 2; }
op=$1 d=$2
l="$d/.lock"
case $op in
  acquire)
    me=${3:?member name required}; timeout=${4:-300}
    start=$(date +%s)
    until mkdir "$l" 2>/dev/null; do
      if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
        echo "lock busy: $(cat "$l/owner" 2>/dev/null || echo 'owner unknown'); not breaking it" >&2
        exit 3
      fi
      sleep 2
    done
    # Random, so tokens stay unique where every process is pid 1 (containers).
    token="$me-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    echo "$token $me at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$l/owner"
    echo "$token" ;;
  release)
    me=${3:?member name required}; token=${4:?token required}
    held=$(cut -d' ' -f1 "$l/owner" 2>/dev/null || true)
    [ "$held" = "$token" ] || { echo "lock not held with this token by $me (owner: $(cut -d' ' -f2- "$l/owner" 2>/dev/null || echo none))" >&2; exit 1; }
    rm -f "$l/owner"; rmdir "$l"
    echo "released by $me" ;;
  show)
    if [ -d "$l" ]; then cat "$l/owner" 2>/dev/null || echo "locked, no owner file"; else echo "unlocked"; fi ;;
  *) echo "unknown op: $op" >&2; exit 2 ;;
esac
