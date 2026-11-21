#!/bin/sh
# post.sh <channel-id> <me> <draft>
# Publishes a draft (the disk message format: YAML front matter, then the
# body) as my next message, <me>-NNN (001-999). The front matter becomes the
# header line `coord <me>-NNN to=... re=... kind=... expects=...`. A message
# with re= goes into the thread of the message it answers; one without re=,
# or of kind done or blocked, goes top-level. The number comes from the
# channel itself. A pending intent preserves the numbered action across an
# interrupted request, and the channel is checked for existing copies.
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

. "$(dirname "$0")/../writer-lib.sh"
writer_enter slack "$ch" "$me"
pending="$writer_dir/post.json"
snap=$(snapshot "$ch" "$me")
if [ "$kind" = readme ]; then
  [ "$(printf '%s' "$snap" | jq -r '.root_user == .myid')" = true ] || die "only the README's author amends it; propose the change in a message"
fi

last=$(printf '%s' "$snap" | jq '[.items[] | select(.mine) | .num] | max // 0')
next=$((last + 1))
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

tick='`'
prefix="${tick}coord $id "
payload=${text#"$prefix"}
if [ -f "$pending" ]; then
  old=$(jq -ce 'select(
      (.id | type) == "string" and (.text | type) == "string"
      and (.thread | type) == "string" and (.accepted_ts | type) == "string"
    )' "$pending") || die "cannot read pending Slack post at $pending"
  old_id=$(printf '%s' "$old" | jq -r '.id')
  landed=$(printf '%s' "$snap" | jq -ce --argjson old "$old" '
    [.items[] | select(.mine and .id == $old.id
      and (if $old.thread == "" then .thread == .ts else .thread == $old.thread end)
      and (if $old.accepted_ts == "" then .text == $old.text else .ts == $old.accepted_ts end))]
    | select(length == 1) | .[0]'
  ) || die "delivery of $old_id is unresolved; no post sent. Retry to refresh Slack history. Pending record: $pending"
  rm "$pending"
  if [ "$(printf '%s' "$old" | jq -r --arg p "${tick}coord $old_id " '.text | ltrimstr($p)')" = "$payload" ]; then
    [ "$(printf '%s' "$old" | jq -r '.accepted_ts')" = "" ] ||
      die "this draft matches $old_id: already posted. Change the draft if a second copy is really meant"
    printf '%s\n' "$landed" | jq -r '"posted \(.id) ts=\(.ts) thread=\(.thread) (recovered)"'
    exit 0
  fi
fi

dup=$(printf '%s' "$snap" | jq -r --arg p "$payload" '
  [.items[] | select(.mine) | .id as $id
    | select((.text | ltrimstr("`coord \($id) ")) == $p)]
  | last | .id // empty')
[ -z "$dup" ] || die "this draft matches $dup: already posted. Change the draft if a second copy is really meant"
[ "$next" -le 999 ] || die "message numbers exhausted for $me (999)"

write_pending() {
  pending_tmp=$(mktemp "$writer_dir/.post.XXXXXX")
  jq -cn --arg id "$id" --arg text "$text" --arg thread "$thread" --arg ts "$1" \
    '{id:$id, text:$text, thread:$thread, accepted_ts:$ts}' > "$pending_tmp"
  mv -f "$pending_tmp" "$pending"
}

write_pending ""
set -- channel="$ch" text="$text" unfurl_links=false unfurl_media=false
[ -z "$thread" ] || set -- "$@" thread_ts="$thread"
if ! r=$(api chat.postMessage "$@"); then
  error=$(printf '%s' "$r" | jq -r '.error // empty' 2>/dev/null || true)
  case $error in
    channel_not_found|not_in_channel|is_archived|not_authed|invalid_auth|token_revoked|account_inactive|missing_scope|no_permission|invalid_arguments|invalid_arg_name|invalid_blocks|msg_too_long|no_text|thread_not_found|restricted_action)
      rm "$pending"
      die "chat.postMessage rejected $id: $error" ;;
    *) die "delivery of $id is unresolved (${error:-no confirmation}); retry to refresh Slack history" ;;
  esac
fi
ts=$(printf '%s' "$r" | jq -er '.ts | strings | select(test("^[0-9]+[.][0-9]+$"))') ||
  die "delivery of $id is unresolved (missing Slack timestamp); retry to refresh Slack history"
write_pending "$ts"
echo "posted $id ts=$ts thread=${thread:-$ts}"
