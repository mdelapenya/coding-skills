#!/bin/sh
# writer.sh token | hold|release <disk|slack> <channel> <me>
set -eu
. "$(dirname "$0")/writer-lib.sh"

if [ "$#" -eq 1 ] && [ "$1" = token ]; then
  od -An -N16 -tx1 /dev/urandom | tr -d ' \n'
  printf '\n'
  exit
fi
[ "$#" -eq 4 ] || { echo "usage: writer.sh token | hold|release <disk|slack> <channel> <me>" >&2; exit 2; }
writer_action=$1; shift
writer_valid_token
writer_state "$@"
writer_lock_op
case $writer_action in
  hold)
    if ! writer_try_guard; then
      writer_error "writer guard already active for $writer_member in $writer_channel"
    fi
    writer_set_owner "$COORD_WRITER_TOKEN"
    exec 9>&-
    trap 'exit 0' HUP INT TERM
    echo "holding $writer_member in $writer_channel"
    # Use a short sleep so inherited descriptors from an interrupted child
    # expire promptly even if only the shell receives a signal.
    while [ "$(cat "$writer_dir/owner")" = "$COORD_WRITER_TOKEN" ]; do
      sleep 1
    done ;;
  release)
    [ -f "$writer_dir/owner" ] || writer_error "no writer guard to release"
    writer_verify_owner
    writer_set_owner ""
    echo "released $writer_member in $writer_channel" ;;
  *) echo "usage: writer.sh token | hold|release <disk|slack> <channel> <me>" >&2; exit 2 ;;
esac
