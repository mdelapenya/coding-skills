#!/bin/sh
# init.sh <topic> <me> <readme-file>
# Creates the private channel #coord-<topic>, invites every member bot and
# the user, posts the README as the channel's root message (first line
# `coord-readme <topic>`), and pins it. The README file must carry, on lines
# of their own:
#   members: claude=U0AAA astra=U0BBB     every member's bot user id, me included
#   user: U0CCC                          the user's Slack member id
# Each member id must be a bot and the user id a person (users.info), and my
# entry must be this token's bot. One bot may appear under one name only.
# Prints the channel id and the README link.
# Refuses an existing channel name: join that channel instead.
set -eu
[ $# -eq 3 ] || { echo "usage: init.sh <topic> <me> <readme-file>" >&2; exit 2; }
. "$(dirname "$0")/lib.sh"
topic=$1 me=$2 readme=$3
printf '%s' "$topic" | grep -Eq '^[a-z0-9][a-z0-9-]{0,73}$' || die "topic must be kebab-case, [a-z0-9-], at most 74 characters"
[ -f "$readme" ] || die "no README at $readme"
body=$(cat "$readme")
members=$(printf '%s\n' "$body" | sed -n 's/^members:[[:space:]]*//p' | head -n1)
user=$(printf '%s\n' "$body" | sed -n 's/^user:[[:space:]]*//p' | head -n1 | tr -d '<>@ ')
[ -n "$members" ] || die "README needs a 'members: name=BOTID ...' line"
[ -n "$user" ] || die "README needs a 'user: MEMBERID' line"
case " $members " in *" $me="*) ;; *) die "README members line does not list $me" ;; esac
text=$(printf '`coord-readme %s`\n\n%s' "$topic" "$body")
[ "$(printf '%s' "$text" | wc -m | tr -d ' ')" -le 12000 ] || die "README over 12000 characters; trim it"

myid=$(my_id)
invite="" seen=" "
for kv in $members; do
  name=${kv%%=*} id=${kv#*=}
  printf '%s' "$name" | grep -Eq '^[a-z0-9]+$' || die "member name '$name' must be [a-z0-9]+"
  case $seen in
    *" $name="*) die "member name $name is listed twice" ;;
    *"=$id "*) other=${seen%%"=$id "*}; die "bot $id is listed as both ${other##* } and $name: sessions sharing one bot in a channel would share its eyes cursor and could post as each other; give each session its own App" ;;
  esac
  seen="$seen$name=$id "
  r=$(api users.info user="$id") || die "users.info $id ($name): $(printf '%s' "$r" | jq -r '.error')"
  [ "$(printf '%s' "$r" | jq -r '.user.is_bot')" = true ] || die "$name=$id is not a bot user; each member is its own Slack App"
  if [ "$name" = "$me" ]; then
    [ "$id" = "$myid" ] || die "README registers $me as $id, but this token is $myid"
  else
    invite="$invite${invite:+,}$id"
  fi
done
r=$(api users.info user="$user") || die "users.info $user (user): $(printf '%s' "$r" | jq -r '.error')"
[ "$(printf '%s' "$r" | jq -r '.user.is_bot')" = false ] || die "user: $user is a bot, not a person"
invite="$invite${invite:+,}$user"

r=$(api conversations.create name="coord-$topic" is_private=true) || {
  e=$(printf '%s' "$r" | jq -r '.error')
  [ "$e" = name_taken ] && die "#coord-$topic already exists: join it (read its README) instead of creating it"
  die "conversations.create: $e"
}
ch=$(printf '%s' "$r" | jq -r '.channel.id')
echo "channel $ch name=#coord-$topic"
r=$(api conversations.invite channel="$ch" users="$invite") || die "conversations.invite: $(printf '%s' "$r" | jq -r '.error'); channel $ch exists without its members"
r=$(api chat.postMessage channel="$ch" text="$text" unfurl_links=false unfurl_media=false) || die "posting the README: $(printf '%s' "$r" | jq -r '.error')"
ts=$(printf '%s' "$r" | jq -r '.ts')
r=$(api pins.add channel="$ch" timestamp="$ts") || echo "warning: could not pin the README: $(printf '%s' "$r" | jq -r '.error')" >&2
link=$(api chat.getPermalink channel="$ch" message_ts="$ts" | jq -r '.permalink // ""') || link=""
echo "readme ts=$ts"
[ -z "$link" ] || echo "link $link"
