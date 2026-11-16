#!/bin/sh
# lib.sh: shared helpers for the Slack scripts. Sourced, never run.
# Needs curl and jq, and SLACK_BOT_TOKEN in the environment: the real token
# (host mode, from docker --env-file) or the Docker Sandboxes placeholder
# (sandbox mode, replaced by the sbx proxy). The token goes only in the
# Authorization header, never in a form field or URL, because the sbx proxy
# substitutes headers only. SLACK_API overrides the endpoint for tests.

SLACK_API=${SLACK_API:-https://slack.com/api}
[ -n "${SLACK_BOT_TOKEN:-}" ] || { echo "SLACK_BOT_TOKEN is not set: no token for this member (see references/slack.md)" >&2; exit 2; }

die() { echo "$*" >&2; exit 1; }

# api <method> [key=value]...  POSTs form-encoded, prints the JSON body.
# Returns 1 when Slack answers ok=false (the body is still printed, so a
# caller can read .error). Honors 429 Retry-After, up to 5 attempts.
api() {
  _m=$1; shift
  _n=$#; _i=0
  while [ "$_i" -lt "$_n" ]; do set -- "$@" --data-urlencode "$1"; shift; _i=$((_i + 1)); done
  _b=$(mktemp) _h=$(mktemp) _try=0
  while :; do
    _code=$(curl -sS --max-time 30 -X POST -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
      -D "$_h" -o "$_b" -w '%{http_code}' "$SLACK_API/$_m" "$@") || { rm -f "$_b" "$_h"; die "network error calling $_m"; }
    if [ "$_code" = 429 ] && [ "$_try" -lt 5 ]; then
      _wait=$(awk -F': *' 'tolower($1)=="retry-after" {print $2+0}' "$_h" | tr -d '\r')
      sleep "${_wait:-5}"; _try=$((_try + 1)); continue
    fi
    break
  done
  [ "$_code" = 200 ] || { rm -f "$_b" "$_h"; die "HTTP $_code calling $_m"; }
  cat "$_b"
  jq -e '.ok == true' "$_b" >/dev/null; _ok=$?
  rm -f "$_b" "$_h"
  return "$_ok"
}

# my_id: the bot user id behind the token.
my_id() {
  _r=$(api auth.test) || die "auth.test failed: $(printf '%s' "$_r" | jq -r '.error // "unknown"')"
  printf '%s' "$_r" | jq -r '.user_id'
}

# fetch_all <channel> [cache-dir]: every message, top-level and thread
# replies, oldest first, normalised to {ts, thread, user, subtype, text,
# edited, eyes}, with Slack's &amp; &lt; &gt; escapes undone so text compares
# with drafts. With a cache dir (watch.sh keeps one per run), a thread is
# re-read only when its reply_count or latest_reply moved, so a quiet poll
# costs one call per history page. The cache lives for one run: reactions and
# edits inside an unchanged thread show on the next run, not mid-run.
fetch_all() {
  _ch=$1 _cache=${2:-} _out=$(mktemp) _c=""
  while :; do
    if [ -n "$_c" ]; then _r=$(api conversations.history channel="$_ch" limit=200 cursor="$_c")
    else _r=$(api conversations.history channel="$_ch" limit=200); fi || { rm -f "$_out"; die "conversations.history: $(printf '%s' "$_r" | jq -r '.error')"; }
    printf '%s' "$_r" | jq -c '.messages[]' >> "$_out"
    _c=$(printf '%s' "$_r" | jq -r '.response_metadata.next_cursor // ""')
    [ -n "$_c" ] || break
  done
  jq -r 'select((.reply_count // 0) > 0) | "\(.ts) \(.reply_count) \(.latest_reply // "")"' "$_out" > "$_out.threads"
  while read -r _t _n _l; do
    if [ -n "$_cache" ] && [ "$(cat "$_cache/$_t.key" 2>/dev/null)" = "$_n $_l" ]; then
      cat "$_cache/$_t.json" >> "$_out"; continue
    fi
    _c="" _th=$(mktemp)
    while :; do
      if [ -n "$_c" ]; then _r=$(api conversations.replies channel="$_ch" ts="$_t" limit=200 cursor="$_c")
      else _r=$(api conversations.replies channel="$_ch" ts="$_t" limit=200); fi || { rm -f "$_out" "$_out.threads" "$_th"; die "conversations.replies: $(printf '%s' "$_r" | jq -r '.error')"; }
      printf '%s' "$_r" | jq -c --arg t "$_t" '.messages[] | select(.ts != $t)' >> "$_th"
      _c=$(printf '%s' "$_r" | jq -r '.response_metadata.next_cursor // ""')
      [ -n "$_c" ] || break
    done
    cat "$_th" >> "$_out"
    if [ -n "$_cache" ]; then mv "$_th" "$_cache/$_t.json"; echo "$_n $_l" > "$_cache/$_t.key"; else rm -f "$_th"; fi
  done < "$_out.threads"
  jq -s 'unique_by(.ts) | sort_by(.ts) | map({
      ts, thread: (.thread_ts // .ts), user: (.user // ""), subtype: (.subtype // ""),
      text: (.text // "" | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&amp;"; "&")), edited: (.edited != null),
      eyes: [.reactions[]? | select(.name == "eyes") | .users[]?]
    })' "$_out"
  rm -f "$_out" "$_out.threads"
}

# CLASSIFY: jq program over fetch_all's output, with --arg me (name) and
# --arg myid. Emits {root, members, user, items}. The root is the first
# top-level message starting with `coord-readme <topic>`; the registry is the
# members:/user: lines of the root, or of the latest kind=readme amendment by
# the root's author that carries them. Each item is classed:
#   member   header names a registered member and the author is that bot
#   user     the registered user, no header
#   foreign  anything else (other people, unregistered bots, forged headers)
# Channel events (joins, pins, topic changes) are dropped.
CLASSIFY='
def hdr: ([.text | split("\n")[0]
  | capture("^`coord (?<name>[a-z0-9]+)-(?<num>[0-9]{3})(?<rest>( [a-z]+=[^ `]*)*)`$")?] | first) as $h
  | if $h == null then null else
      {name: $h.name, num: ($h.num | tonumber),
       fields: ($h.rest | ltrimstr(" ") | if . == "" then {} else
         split(" ") | map(split("=") | {(.[0]): (.[1:] | join("="))}) | add end)}
    end;
def lines_of($p): split("\n") | map(select(startswith($p)) | ltrimstr($p)) | first // null;
def registry($t): {members: ($t | lines_of("members: ") // "" | split(" ") | map(select(. != "") | split("=") | {(.[0]): .[1]}) | add // {}),
                   user: ($t | lines_of("user: ") // "" | gsub("[<>@ ]"; ""))};
map(select(.subtype == "" or .subtype == "bot_message" or .subtype == "thread_broadcast"))
| (map(select(.thread == .ts and (.text | startswith("`coord-readme ")))) | first) as $root
| if $root == null then error("no coord-readme root message in this channel") else . end
| map(. + {h: hdr}) as $all
| ([$root] + [$all[] | select(.user == $root.user and .h != null and .h.fields.kind == "readme"
     and (.text | lines_of("members: ") != null))]) | last | registry(.text) as $reg
| {root: $root.ts, root_user: $root.user, root_text: $root.text, root_edited: $root.edited,
   members: $reg.members, user: $reg.user,
   items: [$all[] | select(.ts != $root.ts)
     | (if .h != null and $reg.members[.h.name] == .user then "member"
        elif .h == null and .user == $reg.user and .user != "" then "user"
        else "foreign" end) as $class
     | {ts, thread, user, text, edited, class: $class,
        name: (if $class == "member" then .h.name else null end),
        num: (if $class == "member" then .h.num else null end),
        id: (if $class == "member" then "\(.h.name)-\(.h.num | tostring | ("00" + .)[-3:])" else null end),
        fields: (if $class == "member" then .h.fields else {} end),
        mine: ($class == "member" and .h.name == $me),
        acked: (.eyes | index($myid) != null)}]}
'

# snapshot <channel> <me> [cache-dir] [my-id]: checks that the token's bot is
# the member <me> registered in the channel, then prints the classified
# channel as JSON. A poller passes a cache dir and the id my_id gave it once,
# so a poll repeats neither auth.test nor unchanged threads.
snapshot() {
  _id=${4:-}
  [ -n "$_id" ] || _id=$(my_id) || exit 1
  _all=$(fetch_all "$1" "${3:-}") || exit 1
  _snap=$(printf '%s' "$_all" | jq --arg me "$2" --arg myid "$_id" "$CLASSIFY") || die "cannot read the channel's README"
  _reg=$(printf '%s' "$_snap" | jq -r --arg me "$2" '.members[$me] // ""')
  [ -n "$_reg" ] || die "$2 is not a member in this channel's README"
  [ "$_reg" = "$_id" ] || die "identity mismatch: the README registers $2 as $_reg, but this token is $_id. Never use another member's token"
  printf '%s' "$_snap" | jq --arg myid "$_id" '. + {myid: $myid}'
}

# norm_id <item>: astra-002, astra-002.md, astra-2 -> astra-002; a ts is kept.
norm_id() {
  case $1 in
    *[!0-9.]*) _x=${1%.md}; printf '%s-%03d' "${_x%-*}" "$(expr "${_x##*-}" + 0)" ;;
    *) printf '%s' "$1" ;;
  esac
}
