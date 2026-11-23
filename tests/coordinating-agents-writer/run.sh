#!/bin/sh
set -eu
unset COORD_WRITER_TOKEN
suite=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
scripts="$suite/../../skills/coordinating-agents/scripts"
tmp=$(mktemp -d)
guard=
next_guard=
slack_guard=
docker_guard=
cleanup() {
  for pid in "$guard" "$next_guard" "$slack_guard"; do
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  done
  if [ -n "$docker_guard" ]; then docker rm -f "$docker_guard" >/dev/null 2>&1 || true; fi
  rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

fail() { echo "FAIL: $*" >&2; exit 1; }
expect_failure() {
  match=$1; shift
  if out=$("$@" 2>&1); then fail "unexpected success: $*"; fi
  printf '%s\n' "$out" | grep -F "$match" >/dev/null || fail "expected '$match' from $*; got $out"
}
wait_for_hold() {
  for _n in 1 2 3 4 5; do
    if grep -q '^holding ' "$1"; then return 0; fi
    sleep 1
  done
  fail "guard failed to start: $(cat "$1")"
}
token=$(sh "$scripts/writer.sh" token)
other=$(sh "$scripts/writer.sh" token)
disk="$tmp/disk"
mkdir "$disk"
printf '%s\n' '---' 'from: alpha # note' '---' message > "$tmp/draft"
sed 's/from: alpha/from: legacy/' "$tmp/draft" > "$tmp/legacy-draft"
printf '%s\n' '---' 'from: alpha' 'from: legacy' '---' message > "$tmp/duplicate-from"
printf '%s\n' '---' 'from: alpha' message > "$tmp/unclosed"
touch "$disk/bob-001.md" "$disk/carol-001.md"
sh "$scripts/post.sh" "$disk" legacy "$tmp/legacy-draft" >/dev/null
COORD_WRITER_TOKEN=$token sh "$scripts/writer.sh" hold disk "$disk" alpha > "$tmp/hold" &
guard=$!
wait_for_hold "$tmp/hold"
expect_failure 'already active' env COORD_WRITER_TOKEN="$other" sh "$scripts/writer.sh" hold disk "$disk" alpha
expect_failure 'set COORD_WRITER_TOKEN' sh "$scripts/post.sh" "$disk" alpha "$tmp/draft"
expect_failure 'does not own' env COORD_WRITER_TOKEN="$other" sh "$scripts/ack.sh" "$disk" alpha bob-001.md
export COORD_WRITER_TOKEN=$token
expect_failure 'must have one from: alpha' sh "$scripts/post.sh" "$disk" alpha "$tmp/legacy-draft"
expect_failure 'must have one from: alpha' sh "$scripts/post.sh" "$disk" alpha "$tmp/duplicate-from"
expect_failure 'must have one from: alpha' sh "$scripts/post.sh" "$disk" alpha "$tmp/unclosed"
sh "$scripts/post.sh" "$disk" alpha "$tmp/draft" > "$tmp/post1" &
p1=$!
sh "$scripts/post.sh" "$disk" alpha "$tmp/draft" > "$tmp/post2" &
p2=$!
wait "$p1"; wait "$p2"
[ -f "$disk/alpha-001.md" ] && [ -f "$disk/alpha-002.md" ] || fail 'same session did not serialize disk posts'
sh "$scripts/ack.sh" "$disk" alpha bob-001.md > "$tmp/ack1" &
p1=$!
sh "$scripts/ack.sh" "$disk" alpha carol-001.md > "$tmp/ack2" &
p2=$!
wait "$p1"; wait "$p2"
[ "$(cat "$disk/alpha.cursor")" = "$(printf 'bob 1\ncarol 1')" ] || fail 'concurrent ACK lost an update'
kill -KILL "$guard"
wait "$guard" 2>/dev/null || true
guard=
# An inherited lock descriptor can live until the guard's current sleep exits.
sleep 2
expect_failure 'guard has exited' sh "$scripts/post.sh" "$disk" alpha "$tmp/draft"
COORD_WRITER_TOKEN=$other sh "$scripts/writer.sh" hold disk "$disk" alpha > "$tmp/takeover" &
next_guard=$!
wait_for_hold "$tmp/takeover"
expect_failure 'does not own' sh "$scripts/post.sh" "$disk" alpha "$tmp/draft"
COORD_WRITER_TOKEN=$other sh "$scripts/post.sh" "$disk" alpha "$tmp/draft" >/dev/null
COORD_WRITER_TOKEN=$other sh "$scripts/writer.sh" release disk "$disk" alpha >/dev/null
wait "$next_guard"; next_guard=
expect_failure 'set COORD_WRITER_TOKEN' env COORD_WRITER_TOKEN= sh "$scripts/post.sh" "$disk" alpha "$tmp/draft"
echo 'ok - disk ownership, serialized writes and crash takeover'

# Match the documented disk workflow. All contenders use the same Docker
# engine and bind mount, with no host-side hold on the same lock files.
docker_disk="$tmp/docker-disk"
mkdir "$docker_disk"
cp "$tmp/draft" "$docker_disk/draft.md"
touch "$docker_disk/beta-001.md"
disk_docker() {
  docker_token=$1; shift
  docker run --rm --user "$(id -u):$(id -g)" --env "COORD_WRITER_TOKEN=$docker_token" \
    --mount "type=bind,source=$scripts,target=/s,readonly" \
    --mount "type=bind,source=$docker_disk,target=/c" "$@"
}
docker_guard=$(disk_docker "$token" -d busybox:1.37-uclibc sh /s/writer.sh hold disk /c alpha)
for _attempt in 1 2 3 4 5; do
  docker logs "$docker_guard" > "$tmp/docker-hold" 2>&1
  if grep -q '^holding ' "$tmp/docker-hold"; then break; fi
  sleep 1
done
grep -q '^holding ' "$tmp/docker-hold" || fail "BusyBox guard failed to start: $(cat "$tmp/docker-hold")"
expect_failure 'already active' disk_docker "$other" busybox:1.37-uclibc sh /s/writer.sh hold disk /c alpha
expect_failure 'does not own' disk_docker "$other" busybox:1.37-uclibc sh /s/post.sh /c alpha /c/draft.md
expect_failure 'set COORD_WRITER_TOKEN' disk_docker '' busybox:1.37-uclibc sh /s/ack.sh /c alpha beta-001.md
disk_docker "$token" busybox:1.37-uclibc sh /s/post.sh /c alpha /c/draft.md >/dev/null
disk_docker "$token" busybox:1.37-uclibc sh /s/ack.sh /c alpha beta-001.md >/dev/null
disk_docker "$token" busybox:1.37-uclibc sh /s/writer.sh release disk /c alpha >/dev/null
[ -f "$docker_disk/alpha-001.md" ] || fail 'BusyBox did not publish into the shared channel'
[ "$(cat "$docker_disk/alpha.cursor")" = 'beta 1' ] || fail 'BusyBox did not ACK into the shared channel'
echo 'ok - BusyBox guard, post, ACK and release on the same Docker engine'

export MOCK_SLACK="$tmp/slack" COORD_WRITER_STATE="$tmp/state" SLACK_BOT_TOKEN=test SLACK_API=https://mock.invalid
mkdir "$MOCK_SLACK"
export PATH="$suite:$PATH"
printf '0\n' > "$MOCK_SLACK/count"
cat > "$MOCK_SLACK/history.json" <<'JSON'
[
  {"ts":"100.000000","user":"UA","text":"`coord-readme test`\nmembers: alpha=UA beta=UB\nuser: UUSER"},
  {"ts":"100.000010","user":"UB","text":"`coord beta-001 to=alpha kind=request expects=reply`\n\nQuestion"}
]
JSON
cat > "$tmp/reply" <<'DRAFT'
---
from: alpha
to: beta
re: beta-001
kind: reply
---
Response to beta.
DRAFT
cat > "$tmp/status" <<'DRAFT'
---
from: alpha
to: beta
kind: status
---
Status after the reply.
DRAFT
sh "$scripts/writer.sh" hold slack CWRITER alpha > "$tmp/slack-hold" &
slack_guard=$!
wait_for_hold "$tmp/slack-hold"
expect_failure 'set COORD_WRITER_TOKEN' env COORD_WRITER_TOKEN= sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/status"
expect_failure 'does not own' env COORD_WRITER_TOKEN="$other" sh "$scripts/slack/ack.sh" CWRITER alpha beta-001
touch "$MOCK_SLACK/lose"
expect_failure 'delivery of alpha-001 is unresolved' sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/reply"
rm "$MOCK_SLACK/lose"
# Later channel activity includes a later numbered message by the same bot.
jq '. + [{"ts":"100.000020","user":"UB","text":"`coord beta-002 to=alpha kind=status expects=none`\n\nMore context"},
         {"ts":"100.000021","user":"UA","text":"`coord alpha-002 to=beta kind=status expects=none`\n\nIntervening update"}]' \
  "$MOCK_SLACK/history.json" > "$MOCK_SLACK/new.json"
mv "$MOCK_SLACK/new.json" "$MOCK_SLACK/history.json"
out=$(sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/reply")
case $out in "posted alpha-001 ts=100.000001 thread=100.000010 (recovered)") ;; *) fail "$out" ;; esac
[ "$(cat "$MOCK_SLACK/count")" = 1 ] || fail 'recovery re-sent the reply'
expect_failure 'matches alpha-001' sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/reply"
sh "$scripts/slack/ack.sh" CWRITER alpha beta-001 >/dev/null
[ -f "$MOCK_SLACK/reacted" ] || fail 'owning session could not ACK'
sed 's/Status after the reply./Another status./' "$tmp/status" > "$tmp/another"
out=$(sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/another")
case $out in "posted alpha-003 ts=100.000002 thread=100.000002") ;; *) fail "$out" ;; esac
expect_failure 'matches alpha-003' sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/another"
touch "$MOCK_SLACK/drop"
expect_failure 'delivery of alpha-004 is unresolved' sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/status"
rm "$MOCK_SLACK/drop"
expect_failure 'delivery of alpha-004 is unresolved' sh "$scripts/slack/post.sh" CWRITER alpha "$tmp/status"
[ "$(cat "$MOCK_SLACK/count")" = 3 ] || fail 'retried a post with no confirmation of delivery or rejection'
sh "$scripts/writer.sh" release slack CWRITER alpha >/dev/null
wait "$slack_guard"; slack_guard=
echo 'ok - Slack ownership, thread recovery, historical duplicate check and unresolved delivery'
