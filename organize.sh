#!/usr/bin/env bash
set -euo pipefail

# Defaults
ACTION=""
TARGET=""
REMOVE_DUPES=false
UNDO=false
LOGFILE=""

usage() {
  cat <<EOF
Usage: $0 (-a | -o) /path/to/folder [--remove-duplicates] [--undo]
  -a                Arrange: normalize names (lowercase, replace spaces), group by base name
  -o                Organize: move files into category folders (images, pdfs, vids, audio, others)
  --remove-duplicates  Remove duplicate files (by SHA256) while keeping one copy
  --undo            Revert the last run recorded in the target folder (reads .organize_history/<timestamp>.log)
Examples:
  ./organize.sh -a /path/to/folder
  ./organize.sh -a -o /path/to/folder --remove-duplicates
  ./organize.sh --undo /path/to/folder
EOF
  exit 1
}

# Parse args
if [ "$#" -lt 1 ]; then usage; fi
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -a) ACTION="arrange"; shift;;
    -o) ACTION="organize"; shift;;
    --remove-duplicates) REMOVE_DUPES=true; shift;;
    --undo) UNDO=true; shift;;
    -*)
      echo "Unknown option: $1"; usage;;
    *)
      TARGET="$1"; shift;;
  esac
done

if [ -z "$TARGET" ]; then usage; fi
if [ ! -d "$TARGET" ]; then echo "Target not a directory: $TARGET"; exit 2; fi

HIST_DIR="$TARGET/.organize_history"
mkdir -p "$HIST_DIR"

timestamp() { date +"%Y%m%dT%H%M%S"; }

log() { printf '%s\n' "$1"; }

# Record an action to logfile (format: ACTION|arg1|arg2...)
record() {
  echo "$1" >> "$LOGFILE"
}

# Normalize filename: lowercase, spaces->underscore, remove problematic chars
normalize() {
  local name="$1"
  local base ext
  ext="${name##*.}"
  if [[ "$name" == "$ext" ]]; then
    base="$name"; ext=""
  else
    base="${name%.*}"
    ext=".${ext,,}"
  fi
  base="$(echo "$base" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:]]+/_/g' | sed -E 's/[^a-z0-9._-]//g')"
  printf '%s%s' "$base" "$ext"
}

# Arrange: rename files to normalized names and group by base name if multiple parts
arrange() {
  log "Arranging files in: $TARGET"
  shopt -s nullglob
  for f in "$TARGET"/*; do
    [ -f "$f" ] || continue
    fname="$(basename -- "$f")"
    nname="$(normalize "$fname")"
    dest="$TARGET/$nname"

    if [ -e "$dest" ]; then
      i=1
      nameOnly="${nname%.*}"
      ext="${nname##*.}"
      if [ "$nameOnly" = "$ext" ]; then
        ext=""; nameOnly="$nname"
      else
        ext=".$ext"
      fi
      while [ -e "$TARGET/${nameOnly}_$i${ext}" ]; do ((i++)); done
      dest="$TARGET/${nameOnly}_$i${ext}"
    fi

    if [ "$f" != "$dest" ]; then
      mv -n -- "$f" "$dest"
      record "RENAME|$dest|$f"
    fi
  done
  shopt -u nullglob
}

# Remove duplicates by SHA256; keep first occurrence
remove_duplicates() {
  log "Removing duplicate files in: $TARGET"
  declare -A seen
  shopt -s nullglob
  while IFS= read -r -d '' file; do
    [ -f "$file" ] || continue
    sum=$(sha256sum "$file" | awk '{print $1}')
    if [[ -n "${seen[$sum]:-}" ]]; then
      # Move duplicates to history folder so they can be restored, rather than permanent delete
      dup_dest="$HIST_DIR/$(basename "$file").dupe_$(timestamp)"
      mv -- "$file" "$dup_dest"
      record "DUP_MOVE|$dup_dest|$file"
    else
      seen[$sum]="$file"
    fi
  done < <(find "$TARGET" -maxdepth 1 -type f -print0)
  shopt -u nullglob
}

# Organize into categories
organize() {
  log "Organizing files into categories in: $TARGET"
  declare -A cats
  cats=(
    [images]="jpg jpeg png gif bmp webp heic heif tiff tif svg"
    [pdfs]="pdf"
    [videos]="mp4 mov mkv webm avi flv m4v mpg mpeg"
    [audio]="mp3 wav flac m4a aac ogg opus"
    [docs]="doc docx xls xlsx ppt pptx txt odt"
    [archives]="zip tar gz tgz bz2 7z rar"
  )

  mkdir -p "$TARGET"/{images,pdfs,vids,audio,docs,archives,others} >/dev/null 2>&1 || true

  shopt -s nullglob nocaseglob
  for f in "$TARGET"/*; do
    [ -f "$f" ] || continue
    ext="${f##*.}"
    lc_ext="${ext,,}"
    moved=false
    for cat in "${!cats[@]}"; do
      for e in ${cats[$cat]}; do
        if [ "$lc_ext" = "$e" ]; then
          case "$cat" in
            images) destdir="$TARGET/images";;
            pdfs) destdir="$TARGET/pdfs";;
            videos) destdir="$TARGET/vids";;
            audio) destdir="$TARGET/audio";;
            docs) destdir="$TARGET/docs";;
            archives) destdir="$TARGET/archives";;
            *) destdir="$TARGET/others";;
          esac
          dest="$destdir/$(basename "$f")"
          mv -n -- "$f" "$dest"
          record "MOVE|$dest|$f"
          moved=true
          break 2
        fi
      done
    done
    if ! $moved; then
      dest="$TARGET/others/$(basename "$f")"
      mv -n -- "$f" "$dest"
      record "MOVE|$dest|$f"
    fi
  done
  shopt -u nullglob nocaseglob
}

# Undo last recorded logfile
undo() {
  # If user provided a logfile timestamp as TARGET, allow that; otherwise, pick latest
  log "Looking for latest history in: $HIST_DIR"
  latest=$(ls -1t "$HIST_DIR"/*.log 2>/dev/null | head -n1 || true)
  if [ -z "$latest" ]; then
    echo "No history log found in $HIST_DIR"; exit 3
  fi
  log "Reverting actions from: $latest"
  # Process in reverse order
  tac "$latest" | while IFS= read -r line; do
    IFS='|' read -r cmd src dst <<< "$line"
    case "$cmd" in
      RENAME)
        # RENAME|newpath|oldpath  => move newpath back to oldpath (if possible)
        if [ -e "$src" ]; then
          mv -n -- "$src" "$dst"
          log "Restored rename: $src -> $dst"
        else
          log "Missing for rename undo: $src"
        fi
        ;;
      MOVE)
        # MOVE|newpath|oldpath  => move file back
        if [ -e "$src" ]; then
          mkdir -p "$(dirname "$dst")"
          mv -n -- "$src" "$dst"
          log "Moved back: $src -> $dst"
        else
          log "Missing for move undo: $src"
        fi
        ;;
      DUP_MOVE)
        # DUP_MOVE|stored_path|original_path => move stored back to original
        if [ -e "$src" ]; then
          mv -n -- "$src" "$dst"
          log "Restored duplicate: $src -> $dst"
        else
          log "Missing for duplicate restore: $src"
        fi
        ;;
      *)
        log "Unknown record: $line"
        ;;
    esac
  done
  # Optionally archive the logfile after undo
  mv -- "$latest" "$latest".reverted 2>/dev/null || true
  log "Undo complete."
}

# Start new logfile unless undo requested
if $UNDO; then
  undo
  exit 0
fi

LOGFILE="$HIST_DIR/$(timestamp).log"
: > "$LOGFILE"

# Run actions in reasonable order: arrange -> remove duplicates -> organize
if [ "$ACTION" = "arrange" ]; then
  arrange
  if $REMOVE_DUPES; then remove_duplicates; fi
elif [ "$ACTION" = "organize" ]; then
  arrange
  if $REMOVE_DUPES; then remove_duplicates; fi
  organize
else
  arrange
  if $REMOVE_DUPES; then remove_duplicates; fi
  organize
fi

log "Done. History saved to $LOGFILE"
