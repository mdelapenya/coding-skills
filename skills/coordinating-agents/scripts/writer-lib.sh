# Shared kernel locks for post.sh, ack.sh and writer.sh. Source from sh.

writer_error() { echo "$*" >&2; exit 1; }

writer_state() {
  writer_transport=$1 writer_channel=$2 writer_member=$3
  case $writer_member in
    ''|.|..|*[!a-zA-Z0-9_.-]*) writer_error "invalid writer member: $writer_member" ;;
  esac
  case $writer_transport in
    disk)
      [ -d "$writer_channel" ] || writer_error "no channel at $writer_channel"
      writer_dir="$writer_channel/.writers/$writer_member" ;;
    slack)
      case $writer_channel in
        ''|*[!a-zA-Z0-9]*) writer_error "invalid Slack channel ID: $writer_channel" ;;
      esac
      if [ -n "${COORD_WRITER_TOKEN:-}" ] && [ -z "${COORD_WRITER_STATE:-}" ]; then
        writer_error "set COORD_WRITER_STATE to the shared Slack writer state directory"
      fi
      writer_root=${COORD_WRITER_STATE:-${TMPDIR:-/tmp}/coordinating-agents-writers-$(id -u)}
      case $writer_root in /*) ;; *) writer_error "COORD_WRITER_STATE must be an absolute path" ;; esac
      writer_dir="$writer_root/$writer_channel/$writer_member" ;;
    *) writer_error "writer transport must be disk or slack" ;;
  esac
  (umask 077; mkdir -p "$writer_dir") || writer_error "cannot create writer state at $writer_dir"
  if command -v flock >/dev/null 2>&1; then
    writer_backend=flock
  elif command -v lockf >/dev/null 2>&1; then
    writer_backend=lockf
  else
    writer_error "writer ownership requires flock or BSD lockf"
  fi
}

# Locks stay with the shell's open descriptor, including descendants doing
# the actual write. The lock files must always keep the same inode.
writer_lock_op() {
  exec 9>>"$writer_dir/operation.lock"
  case $writer_backend in
    flock) flock 9 ;;
    lockf) lockf 9 ;;
  esac || writer_error "cannot lock writer operations at $writer_dir"
}

# Returns 0 when we acquired the guard lock, 1 when another process holds it.
writer_try_guard() {
  exec 8>>"$writer_dir/session.lock"
  case $writer_backend in
    flock)
      if flock -n 8; then return 0; else writer_rc=$?; fi
      [ "$writer_rc" -eq 1 ] || writer_error "cannot check the writer guard" ;;
    lockf)
      if lockf -t 0 8 2>/dev/null; then return 0; else writer_rc=$?; fi
      [ "$writer_rc" -eq 75 ] || writer_error "cannot check the writer guard" ;;
  esac
  exec 8>&-
  return 1
}

writer_valid_token() {
  case ${COORD_WRITER_TOKEN:-} in
    ''|*[!a-f0-9]*) writer_error "set COORD_WRITER_TOKEN using writer.sh token" ;;
  esac
  [ "${#COORD_WRITER_TOKEN}" -eq 32 ] || writer_error "set COORD_WRITER_TOKEN using writer.sh token"
}

writer_verify_owner() {
  writer_valid_token
  [ "$(cat "$writer_dir/owner")" = "$COORD_WRITER_TOKEN" ] ||
    writer_error "this session does not own $writer_member in $writer_channel"
  if writer_try_guard; then
    writer_error "writer guard has exited for $writer_member in $writer_channel; start a new hold"
  fi
}

writer_enter() {
  writer_state "$@"
  writer_lock_op
  if [ -e "$writer_dir/owner" ] || [ -n "${COORD_WRITER_TOKEN:-}" ]; then
    [ -f "$writer_dir/owner" ] || writer_error "start the writer guard before writing"
    writer_verify_owner
  fi
}

writer_set_owner() {
  writer_owner_tmp=$(mktemp "$writer_dir/.owner.XXXXXX") || writer_error "cannot stage writer ownership"
  printf '%s\n' "$1" > "$writer_owner_tmp"
  mv -f "$writer_owner_tmp" "$writer_dir/owner"
}
