#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wt-env-tests.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
SOURCE="$TEMP_DIR/primary repo's clone"
DESTINATION="$TEMP_DIR/feature repo"
mkdir -p "$SOURCE" "$DESTINATION"

create() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "${2:-SECRET=local}" > "$1"
}

copy() {
  bash "$SCRIPT_DIR/copy-env-local.sh" "$SOURCE" "$DESTINATION"
}

# Empty repositories and same-worktree invocation are no-ops.
copy
bash "$SCRIPT_DIR/copy-env-local.sh" "$SOURCE" "$SOURCE"

# Root, monorepo, and unusual paths retain contents and permissions.
for relative in .env.local apps/web/.env.local 'packages/shared config/.env.local' $'apps/new\nline/.env.local'; do
  create "$SOURCE/$relative"
  chmod 600 "$SOURCE/$relative"
done
create "$SOURCE/.env"
create "$SOURCE/apps/web/.env.production"
copy
for relative in .env.local apps/web/.env.local 'packages/shared config/.env.local' $'apps/new\nline/.env.local'; do
  cmp "$SOURCE/$relative" "$DESTINATION/$relative"
  [[ "$(LC_ALL=C ls -l "$DESTINATION/$relative")" == -rw-------* ]]
done
[[ ! -e "$DESTINATION/.env" && ! -e "$DESTINATION/apps/web/.env.production" ]]

# Existing files stay intact on repeated runs.
create "$DESTINATION/.env.local" 'SECRET=custom'
copy
[[ "$(cat "$DESTINATION/.env.local")" == 'SECRET=custom' ]]

# Dependencies, generated output, nested repos, worktrees, and submodules skip.
for directory in .git .hg .svn node_modules .venv venv vendor .next .nuxt .turbo .cache dist build coverage .worktrees; do
  create "$SOURCE/$directory/.env.local"
done
create "$SOURCE/nested-repo/.git/HEAD"
create "$SOURCE/nested-repo/.env.local"
create "$SOURCE/linked-worktree/.git" 'gitdir: /some/repo/.git/worktrees/feature'
create "$SOURCE/linked-worktree/.env.local"
copy
[[ "$(find "$DESTINATION" -name .env.local -exec printf x \; | wc -c | tr -d ' ')" == 4 ]]

# Destination nested inside source must not be copied back into itself.
mkdir -p "$SOURCE/feature"
create "$SOURCE/feature/nested/.env.local"
bash "$SCRIPT_DIR/copy-env-local.sh" "$SOURCE" "$SOURCE/feature"
[[ -f "$SOURCE/feature/.env.local" && ! -e "$SOURCE/feature/feature" ]]

# Source symlinks are not followed.
mkdir -p "$TEMP_DIR/outside"
create "$TEMP_DIR/outside/.env.local"
ln -s "$TEMP_DIR/outside" "$SOURCE/external"
ln -s "$TEMP_DIR/outside/.env.local" "$SOURCE/apps/web/linked.env"
mkdir -p "$SOURCE/symlink-file"
ln -s "$TEMP_DIR/outside/.env.local" "$SOURCE/symlink-file/.env.local"
copy
[[ ! -e "$DESTINATION/external" && ! -e "$DESTINATION/symlink-file" ]]

# Destination symlinks (including dangling ones) and non-directory parents skip.
create "$SOURCE/unsafe/web/.env.local"
ln -s "$TEMP_DIR/outside" "$DESTINATION/unsafe"
create "$SOURCE/dangling/.env.local"
mkdir -p "$DESTINATION/dangling"
ln -s "$TEMP_DIR/outside/missing" "$DESTINATION/dangling/.env.local"
create "$SOURCE/blocked/lib/.env.local"
create "$DESTINATION/blocked" 'not a directory'
copy
[[ ! -e "$TEMP_DIR/outside/web" && ! -e "$TEMP_DIR/outside/missing" ]]
[[ -L "$DESTINATION/dangling/.env.local" ]]

printf 'PASS: copy paths, permissions, repeatability, exclusions, nested destinations, and symlink handling\n'
