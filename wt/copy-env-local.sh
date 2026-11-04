#!/bin/bash

# Copy .env.local files from the primary worktree, keeping relative paths.
# Compatible with the Bash 3.2 shipped with macOS.
set -euo pipefail
shopt -s dotglob nullglob

if [[ $# -ne 2 ]]; then
  echo "Usage: copy-env-local.sh SOURCE_WORKTREE DESTINATION_WORKTREE" >&2
  exit 1
fi

SOURCE="$(cd "$1" && pwd -P)"
DESTINATION="$(cd "$2" && pwd -P)"
[[ "$SOURCE" != "$DESTINATION" ]] || exit 0
COPIED=0

copy_directory() {
  local directory="$1" relative="$2" target parent part remaining entry name

  if [[ -f "$directory/.env.local" && ! -L "$directory/.env.local" ]]; then
    target="$DESTINATION/$relative.env.local"
    parent="$DESTINATION"
    # Check each destination parent before mkdir/cp: never follow symlinks
    # outside the worktree or overwrite existing environment files.
    remaining="$relative"
    while [[ -n "$remaining" ]]; do
      part="${remaining%%/*}"
      remaining="${remaining#*/}"
      parent="$parent/$part"
      if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
        return 0
      fi
    done
    if [[ ! -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$parent"
      cp -p -n "$directory/.env.local" "$target"
      COPIED=$((COPIED + 1))
      printf 'Copied %s.env.local\n' "$relative"
    fi
  fi

  for entry in "$directory"/*; do
    [[ -d "$entry" && ! -L "$entry" && "$entry" != "$DESTINATION" ]] || continue
    name="${entry##*/}"
    case "$name" in
      .git|.hg|.svn|node_modules|.venv|venv|vendor|.next|.nuxt|.turbo|.cache|dist|build|coverage|.worktrees)
        continue ;;
    esac
    # .git files mark linked worktrees/submodules; directories mark nested repos.
    [[ ! -e "$entry/.git" && ! -L "$entry/.git" ]] || continue
    copy_directory "$entry" "$relative$name/"
  done
}

copy_directory "$SOURCE" ""
if [[ "$COPIED" -gt 0 ]]; then
  printf 'Copied %s .env.local file(s) from the primary worktree\n' "$COPIED"
fi
