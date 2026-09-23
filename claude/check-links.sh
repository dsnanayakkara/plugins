#!/bin/sh
# Fails if any link under the Claude plugin is broken or resolves outside the repository.
# claude plugin install drops such links silently, so run this before every version bump.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd -P)"
target="${1:-$root/claude/pstack}"
status=0

broken="$(find -L "$target" -type l)"
if [ -n "$broken" ]; then
  printf 'broken link: %s\n' $broken >&2
  status=1
fi

find -L "$target" | while IFS= read -r path; do
  resolved="$(realpath "$path" 2>/dev/null)" || continue
  case "$resolved" in
    "$root" | "$root"/*) ;;
    *) printf 'outside repo: %s -> %s\n' "$path" "$resolved" >&2; exit 1 ;;
  esac
done || status=1

[ "$status" -eq 0 ] && echo "links ok"
exit "$status"
