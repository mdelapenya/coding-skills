#!/bin/sh
# post.sh <channel-id> <me> <draft>
# Publishes a draft (the disk message format: YAML front matter, then the
# body) as my next message, <me>-NNN (001-999). The front matter becomes the
# header line `coord <me>-NNN to=... re=... kind=... expects=...`. A message
# with re= goes into the thread of the message it answers; one without re=,
# or of kind done or blocked, goes top-level. The number comes from the
# channel itself, so a restart or another machine cannot reuse one, and a
# draft whose header and body match my latest message is refused as a
# likely double post. Never edits or deletes anything.
set -eu
[ $# -eq 3 ] || { echo "usage: post.sh <channel-id> <me> <draft>" >&2; exit 2; }
. "$(dirname "$0")/lib.sh"
ch=$1 me=$2 draft=$3
[ -f "$draft" ] || die "no draft at $draft"

fm=$(awk 'NR==1 && $0!="---" {exit 1} NR>1 && $0=="---" {exit} NR>1 {sub(/[ \t]+#.*$/, ""); print}' "$draft") \
  || die "draft must start with a --- front matter block"
body=$(awk 'n>=2 {print; next} $0=="---" {n++}' "$draft" | sed '/./,$!d')
[ -n "$body" ] || die "draft has no body"
get() { printf '%s\n' "$fm" | sed -n "s/^$1:[[:space:]]*//p" | head -n1; }
from=$(get from) to=$(get to) re=$(get re) kind=$(get kind) expects=$(get expects)
lock=$(get lock) unlock=$(get unlock)
[ "$from" = "$me" ] || die "draft says from: '$from', but I am $me"
[ -n "$to" ] || die "draft needs to:"
case $kind in
  request|reply|review|evidence|status|decision-needed|proposal|vote|delivery|done|blocked|readme) ;;
  *) die "kind must be request|reply|review|evidence|status|decision-needed|proposal|vote|delivery|done|blocked|readme, not '$kind'" ;;
esac
expects=${expects:-none}
case $expects in reply|ack|none) ;; *) die "expects must be reply|ack|none" ;; esac
for v in "$to" "$re" "$lock" "$unlock"; do
  case $v in *[[:space:]\`]*) die "header values cannot contain spaces or backticks: '$v'" ;; esac
done

snap=$(snapshot "$ch" "$me")
if [ "$kind" = readme ]; then
  [ "$(printf '%s' "$snap" | jq -r '.root_user == .myid')" = true ] || die "only the README's author amends it; propose the change in a message"
fi

last=$(printf '%s' "$snap" | jq '[.items[] | select(.mine) | .num] | max // 0')
next=$((last + 1))
[ "$next" -le 999 ] || die "message numbers exhausted for $me (999)"
id=$(printf '%s-%03d' "$me" "$next")

thread=""
if [ -n "$re" ] && [ "$kind" != "done" ] && [ "$kind" != "blocked" ]; then
  re=$(norm_id "$re")
  thread=$(printf '%s' "$snap" | jq -r --arg re "$re" '[.items[] | select(.id == $re or .ts == $re) | .thread] | first // ""')
  [ -n "$thread" ] || die "re: $re is not a message in this channel"
elif [ -n "$re" ]; then
  re=$(norm_id "$re")
fi

hdr="coord $id to=$to"
[ -z "$re" ] || hdr="$hdr re=$re"
hdr="$hdr kind=$kind expects=$expects"
[ -z "$lock" ] || hdr="$hdr lock=$lock"
[ -z "$unlock" ] || hdr="$hdr unlock=$unlock"
text=$(printf '`%s`\n\n%s' "$hdr" "$body")
len=$(printf '%s' "$text" | wc -m | tr -d ' ')
[ "$len" -le 4000 ] || die "message is $len characters; keep it under 4000 (put an excerpt and the command that produced it)"

dup=$(printf '%s' "$snap" | jq -r --arg h "${hdr#"coord $id "}" --arg b "$body" '
  [.items[] | select(.mine)] | last // empty
  | (.text | split("\n")) as $l
  | select(($l[0] | sub("^`coord [a-z0-9]+-[0-9]{3} "; "") | rtrimstr("`")) == $h and ($l[2:] | join("\n")) == $b)
  | .id')
[ -z "$dup" ] || die "this draft matches $dup, my latest message: probably already posted. Change the draft if a second copy is really meant"

if [ -n "$thread" ]; then
  r=$(api chat.postMessage channel="$ch" text="$text" thread_ts="$thread" unfurl_links=false unfurl_media=false) \
    || die "chat.postMessage: $(printf '%s' "$r" | jq -r '.error'). Run post.sh again: it re-reads the channel first"
else
  r=$(api chat.postMessage channel="$ch" text="$text" unfurl_links=false unfurl_media=false) \
    || die "chat.postMessage: $(printf '%s' "$r" | jq -r '.error'). Run post.sh again: it re-reads the channel first"
fi
ts=$(printf '%s' "$r" | jq -r '.ts')
echo "posted $id ts=$ts thread=${thread:-$ts}"
