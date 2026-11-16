#!/bin/sh
# invite.sh <channel-id> <me> <member>...
# Invites members the README already registers into an existing channel.
# Register them first: the README's author posts a kind=readme amendment
# whose members: line lists everyone, the new member included; invite.sh
# reads that registry, so it never brings in a bot the channel does not
# name. Each member must be a bot registered under one name only. A member
# already in the channel is reported, not an error. Needs channels:manage
# (public channel) or groups:write (private).
set -eu
[ $# -ge 3 ] || { echo "usage: invite.sh <channel-id> <me> <member>..." >&2; exit 2; }
. "$(dirname "$0")/lib.sh"
ch=$1 me=$2; shift 2
snap=$(snapshot "$ch" "$me")
for who in "$@"; do
  [ "$who" != "$me" ] || die "not inviting yourself: you are already in the channel"
  id=$(printf '%s' "$snap" | jq -r --arg w "$who" '.members[$w] // ""')
  [ -n "$id" ] || die "$who is not in this channel's README: post a kind=readme amendment with the full members: line first (only the README's author can)"
  n=$(printf '%s' "$snap" | jq -r --arg id "$id" '[.members[] | select(. == $id)] | length')
  [ "$n" -eq 1 ] || die "bot $id is registered under $n names: sessions sharing one bot in a channel would share its eyes cursor; give each its own App"
  r=$(api users.info user="$id") || die "users.info $id ($who): $(printf '%s' "$r" | jq -r '.error')"
  [ "$(printf '%s' "$r" | jq -r '.user.is_bot')" = true ] || die "$who=$id is not a bot user; each member is its own Slack App"
  if r=$(api conversations.invite channel="$ch" users="$id"); then
    echo "invited $who ($id)"
  else
    e=$(printf '%s' "$r" | jq -r '.error')
    case $e in
      already_in_channel) echo "already in channel: $who ($id)" ;;
      missing_scope) die "conversations.invite: missing_scope. A public channel needs channels:manage, a private one groups:write" ;;
      *) die "conversations.invite $who: $e" ;;
    esac
  fi
done
