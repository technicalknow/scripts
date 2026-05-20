## organize.sh — README

### Summary
organize.sh renames, de-duplicates, and sorts files in a target folder. It records all actions so they can be undone.

### Requirements
- bash (GNU bash)
- coreutils (mv, find, sha256sum, mkdir, ls, mv, tac)
- chmod +x organize.sh

### Installation
1. Save the script as `organize.sh`.
2. Make executable:
```
chmod +x organize.sh
```

### Location of history logs
- History logs and stored duplicates are kept in: <target>/.organize_history

### Usage
Basic forms:
- Arrange only:
```
./organize.sh -a /path/to/folder
```
- Arrange + remove duplicates:
```
./organize.sh -a /path/to/folder --remove-duplicates
```
- Organize into categories (also runs arrange first):
```
./organize.sh -o /path/to/folder
```
- Arrange + Organize + remove duplicates:
```
./organize.sh -a -o /path/to/folder --remove-duplicates
```
- Undo the last run (revert actions recorded in the target folder):
```
./organize.sh --undo /path/to/folder
```

Notes:
- If both -a and -o are provided the script arranges first, removes duplicates if requested, then organizes.
- The script operates at the target folder top level (non-recursive).
- Duplicate detection uses SHA256; duplicates are moved into the history directory (not permanently deleted) so they can be restored.
- Actions are logged per-run in .organize_history/<timestamp>.log with records:
  - RENAME|<newpath>|<oldpath>
  - MOVE|<newpath>|<oldpath>
  - DUP_MOVE|<stored_path>|<original_path>
- Undo uses the most recent .log in .organize_history and applies records in reverse order. After undo the log is renamed with a .reverted suffix.

### Categories used by organize
- images: jpg, jpeg, png, gif, bmp, webp, heic, heif, tiff, tif, svg
- pdfs: pdf
- vids: mp4, mov, mkv, webm, avi, flv, m4v, mpg, mpeg
- audio: mp3, wav, flac, m4a, aac, ogg, opus
- docs: doc, docx, xls, xlsx, ppt, pptx, txt, odt
- archives: zip, tar, gz, tgz, bz2, 7z, rar
- others: any non-matching extensions

### Behavior details & safe defaults
- Filenames are normalized: lowercased, spaces → underscores, non-alphanumeric characters removed (conservative).
- When renaming/moving would overwrite an existing file, a numeric suffix is appended to avoid data loss.
- The script records moves/renames/de-duplicate moves so they can be undone; it does not track external changes made after the run.
- The script is non-recursive (top-level only). To make it recursive, adjust find and loops accordingly.

### Troubleshooting
- "No history log found": ensure .organize_history exists and contains .log files in the target folder.
- Missing files during undo: files may have been modified/moved/deleted outside the script — undo will skip and report them.
- Permission errors: run with appropriate permissions or adjust file ownership.

### Example workflow
1. Arrange and de-duplicate:
```
./organize.sh -a /home/user/Downloads --remove-duplicates
```
2. Organize into folders:
```
./organize.sh -o /home/user/Downloads
```
3. If needed, undo last operation:
```
./organize.sh --undo /home/user/Downloads
```

