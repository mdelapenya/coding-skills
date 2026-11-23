# Writer ownership

Run one guard for each member and channel for the life of the session. Both
`post.sh` and `ack.sh` check the same ownership and serialize even simultaneous
calls from the owning session. Keep the token in that session, along with any
process it delegates its writes to. Read and watch commands work without it.

## Disk with BusyBox

Use the same Docker engine and channel bind mount for `hold`, `post.sh`,
`ack.sh` and `release`. The lock belongs to the kernel running those
containers. Docker Desktop runs a separate Linux kernel, so a host shell
cannot guard the containers' writes.

These commands use literal paths and work in PowerShell and POSIX shells.
On Linux add the same `--user <uid>:<gid>` to every command. Use a unique
name for the guard container and keep its ID for recovery.

```text
docker run --rm --mount "type=bind,source=<absolute scripts dir>,target=/s,readonly" busybox:1.37-uclibc sh /s/writer.sh token
```

Set `COORD_WRITER_TOKEN` in the owning shell to the result (`export` in a
POSIX shell, `$env:COORD_WRITER_TOKEN = '<result>'` in PowerShell). Then start
the guard and check its logs.

```text
docker run --rm -d --name <guard> --env COORD_WRITER_TOKEN --mount "type=bind,source=<absolute scripts dir>,target=/s,readonly" --mount "type=bind,source=<absolute channel dir>,target=/c" busybox:1.37-uclibc sh /s/writer.sh hold disk /c <me>
docker logs <guard>
```

Wait for the guard to print `holding`. Use `--env COORD_WRITER_TOKEN` and the
same mounts for all writes and for release.

```text
docker run --rm --env COORD_WRITER_TOKEN --mount "type=bind,source=<absolute scripts dir>,target=/s,readonly" --mount "type=bind,source=<absolute channel dir>,target=/c" busybox:1.37-uclibc sh /s/post.sh /c <me> /c/<me>/drafts/<file>
docker run --rm --env COORD_WRITER_TOKEN --mount "type=bind,source=<absolute scripts dir>,target=/s,readonly" --mount "type=bind,source=<absolute channel dir>,target=/c" busybox:1.37-uclibc sh /s/ack.sh /c <me> <item>
docker run --rm --env COORD_WRITER_TOKEN --mount "type=bind,source=<absolute scripts dir>,target=/s,readonly" --mount "type=bind,source=<absolute channel dir>,target=/c" busybox:1.37-uclibc sh /s/writer.sh release disk /c <me>
```

The guard exits after release. With explicit authorization to use the host
shell, keep all four operations on that host and use the native paths.

```sh
export COORD_WRITER_TOKEN="$(sh "$SCRIPTS/writer.sh" token)"
sh "$SCRIPTS/writer.sh" hold disk "$CHANNEL_DIR" "$ME" &
guard=$!
# Wait for the guard to print "holding" before posting or acking.
sh "$SCRIPTS/post.sh" "$CHANNEL_DIR" "$ME" "$DRAFT"
sh "$SCRIPTS/writer.sh" release disk "$CHANNEL_DIR" "$ME"
wait "$guard"
```

## Slack sandbox

For Slack running directly in a sandbox, create a private state directory on a
persistent filesystem. Use the same location for every session that may write
under the same member identity in that channel.

```sh
export COORD_WRITER_STATE="$WORKER_STATE/slack-writers"
(umask 077; mkdir -p "$COORD_WRITER_STATE")
export COORD_WRITER_TOKEN="$(sh "$SCRIPTS/writer.sh" token)"
sh "$SCRIPTS/writer.sh" hold slack "$CHANNEL_ID" "$ME" &
guard=$!
# Wait for "holding", then run the usual Slack writer scripts.
sh "$SCRIPTS/slack/post.sh" "$CHANNEL_ID" "$ME" "$DRAFT"
sh "$SCRIPTS/writer.sh" release slack "$CHANNEL_ID" "$ME"
wait "$guard"
```

Run the guard as a managed background job so stopping the worker also stops its
guard. After a crash, a new session starts a guard with a new token once the
old process has exited. When a worker can no longer release its guard, stop
the old guard by its exact process or container ID. A slow worker keeps its
claim for as long as its guard is alive. Keep the lock files and owner marker
in place, including after release.

## Slack from short-lived Docker commands

Use one named Docker volume for the writer state for the same workspace on
the same Docker engine. Continue to pass the Slack credentials using the
usual env file for posts and ACKs. The guard uses only the state volume.

```sh
volume=coord-slack-writers
docker volume create "$volume"
# Initialize the new volume for the image's nobody user.
docker run --rm --user 0 --mount "type=volume,source=$volume,target=/writer" \
  "$IMAGE" sh -c 'chown nobody /writer && chmod 700 /writer'
export COORD_WRITER_TOKEN="$(sh "$SCRIPTS/writer.sh" token)"
writer_docker() {
  docker run --rm --env COORD_WRITER_TOKEN --env COORD_WRITER_STATE=/writer \
    --mount "type=volume,source=$volume,target=/writer" \
    --mount "type=bind,source=$SCRIPTS,target=/s,readonly" "$@"
}
writer_docker "$IMAGE" sh /s/writer.sh hold slack "$CHANNEL_ID" "$ME" &
guard=$!
# Wait for "holding".
writer_docker --env-file "$SLACK_ENV_FILE" \
  --mount "type=bind,source=$DRAFT_DIR,target=/d,readonly" \
  "$IMAGE" sh /s/slack/post.sh "$CHANNEL_ID" "$ME" /d/draft.md
writer_docker "$IMAGE" sh /s/writer.sh release slack "$CHANNEL_ID" "$ME"
wait "$guard"
```

The same volume and token options apply to `/s/slack/ack.sh`. Keep the guard's
Docker container ID if the client runs detached or can be disconnected.
A disconnected Docker client can leave its container running.

## Migration and recovery

The scripts accept the old arguments on channels that have never been claimed
in their state directory. The first successful hold upgrades that member on
that channel. From then on tokenless writers using that state are rejected,
including after release. Arrange the shared state mount for all writers before
claiming Slack ownership. An older script or a command with an independent
filesystem can bypass a local claim. Slack's message and reaction APIs do not
provide a distributed ownership lock. Share the same volume and locking
kernel, and keep a member on one writer environment at a time. For disk,
state is under the channel's `.writers/<member>/`. Both paths require
`flock` on Linux or the BSD `lockf` utility on macOS.

On a Slack post with an uncertain outcome, retry the same draft with the same
state. The script checks the full history and threads for that member's
original numbered post. A recovered post prints its original ID and timestamp.
If the outcome remains uncertain, later posts stop before sending. Slack may
still deliver an in-flight request, so absence in history does not establish
rejection. Resolve the pending record by verifying the original outcome with
the Slack administrator before changing it. Once a post is confirmed in the
channel, future duplicate checks use Slack history, so they cover messages
available under the workspace's retention policy. Protect the state directory
and its backups as you would a private channel draft because pending posts
store the text.
