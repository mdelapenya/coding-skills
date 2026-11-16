#!/bin/sh
# ack.sh <channel-id> <me> <item>...
# Records items as read by adding an eyes reaction from my bot. Items are
# what watch.sh printed: a member message id (astra-003) or a ts (for user
# and foreign messages). A member's messages are acked in order: acking
# astra-003 requires astra-002 to be acked already or earlier in the same
# call, so a typo or a skipped message can never hide later ones. Eyes means
# "read", never "agreed" or "obeyed".
set -eu
[ $# -ge 3 ] || { echo "usage: ack.sh <channel-id> <me> <item>..." >&2; exit 2; }
. "$(dirname "$0")/lib.sh"
ch=$1 me=$2; shift 2
snap=$(snapshot "$ch" "$me")
acked_now=" "
for raw in "$@"; do
  item=$(norm_id "$raw")
  m=$(printf '%s' "$snap" | jq -c --arg i "$item" '[.items[] | select(.id == $i or .ts == $i)] | first // empty')
  [ -n "$m" ] || die "no such item in channel: $raw"
  [ "$(printf '%s' "$m" | jq -r '.mine')" = false ] || die "not acking your own item: $raw"
  ts=$(printf '%s' "$m" | jq -r '.ts')
  if [ "$(printf '%s' "$m" | jq -r '.class')" = member ]; then
    gap=$(printf '%s' "$snap" | jq -r --argjson m "$m" --arg seen "$acked_now" '
      [.items[] | select(.class == "member" and .name == $m.name and .num < $m.num and (.acked | not)
        and (.ts as $t | $seen | contains(" \($t) ") | not))] | sort_by(.num) | first | .id // empty')
    [ -z "$gap" ] || die "gap: ack $gap first"
  fi
  if [ "$(printf '%s' "$m" | jq -r '.acked')" = true ]; then
    echo "already acked $raw"
  else
    r=$(api reactions.add channel="$ch" timestamp="$ts" name=eyes) \
      || [ "$(printf '%s' "$r" | jq -r '.error')" = already_reacted ] \
      || die "reactions.add $raw: $(printf '%s' "$r" | jq -r '.error')"
    echo "acked $raw"
  fi
  acked_now="$acked_now$ts "
done
