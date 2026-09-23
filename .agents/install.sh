#!/bin/sh
# Links every skill in .agents/skills into ~/.agents/skills so Codex loads them in any repository.
set -eu

src="$(cd "$(dirname "$0")/skills" && pwd)"
dest="$HOME/.agents/skills"
mkdir -p "$dest"

for skill in "$src"/*/; do
  name="$(basename "$skill")"
  target="$dest/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "skip $name: $target exists and is not a symlink" >&2
    continue
  fi
  ln -sfn "$src/$name" "$target"
  echo "linked $name"
done
