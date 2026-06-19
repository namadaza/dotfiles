#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_SRC="$SCRIPT_DIR/../nvim"
NVIM_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

merge_spell_file() {
  local src_file="$1"
  local dest_file="$2"

  [[ -f "$src_file" || -f "$dest_file" ]] || return 0

  local tmpdir merged
  local inputs=()
  tmpdir="$(mktemp -d)"
  merged="$tmpdir/merged"

  [[ -f "$src_file" ]] && inputs+=("$src_file")
  [[ -f "$dest_file" ]] && inputs+=("$dest_file")
  awk '!seen[$0]++' "${inputs[@]}" > "$merged"

  mkdir -p "$(dirname "$src_file")" "$(dirname "$dest_file")"
  cp "$merged" "$src_file"
  cp "$merged" "$dest_file"
  rm -rf "$tmpdir"
}

sync_spell_files() {
  local src_spell_dir="$NVIM_SRC/spell"
  local dest_spell_dir="$NVIM_DEST/spell"
  local files=()
  local processed=""
  local file basename

  shopt -s nullglob
  files+=("$src_spell_dir"/*.add)
  files+=("$dest_spell_dir"/*.add)
  shopt -u nullglob

  for file in "${files[@]}"; do
    basename="${file##*/}"
    case " $processed " in
      *" $basename "*) continue ;;
    esac

    processed="$processed $basename"
    merge_spell_file "$src_spell_dir/$basename" "$dest_spell_dir/$basename"
  done
}

mkdir -p "$NVIM_DEST"
sync_spell_files
rsync -a --exclude ".git/" "$NVIM_SRC"/ "$NVIM_DEST"/
