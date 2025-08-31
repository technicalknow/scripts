#!/usr/bin/env bash
# Requires: dmenu, alacritty, yt-dlp, ffmpeg
DEST="$HOME/Downloads"

CHOICE=$(printf "Audio\nVideo" | dmenu -i -p "Download type:")
[ -z "$CHOICE" ] && exit 0

# Try to prefill dmenu with the clipboard to allow easy paste on X11/Wayland.
# Prefer wl-paste on Wayland, fall back to xclip/xsel on X11, otherwise present empty input so typing works.
if command -v wl-paste >/dev/null 2>&1; then
  CLIP=$(wl-paste 2>/dev/null || echo "")
elif command -v xclip >/dev/null 2>&1; then
  CLIP=$(xclip -o -selection clipboard 2>/dev/null || xclip -o 2>/dev/null || echo "")
elif command -v xsel >/dev/null 2>&1; then
  CLIP=$(xsel --clipboard --output 2>/dev/null || xsel --output 2>/dev/null || echo "")
else
  CLIP=""
fi

# If CLIP is non-empty, feed it to dmenu so you can edit/paste easily. Otherwise provide empty stdin.
if [ -n "$CLIP" ]; then
  URL=$(printf "%s" "$CLIP" | dmenu -i -p "Enter URL:")
else
  URL=$(printf "" | dmenu -i -p "Enter URL:")
fi

[ -z "$URL" ] && exit 0

case "$CHOICE" in
  Audio)
    YTDLP_CMD=(yt-dlp -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 --embed-thumbnail --add-metadata -o "$DEST/%(title)s.%(ext)s" "$URL")
    ;;
  Video)
    YTDLP_CMD=(yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 --embed-thumbnail --add-metadata -o "$DEST/%(title)s.%(ext)s" "$URL")
    ;;
  *)
    exit 0
    ;;
esac

# Build a safely quoted command string
printf -v CMD_STR "%q " "${YTDLP_CMD[@]}"

# Open Alacritty and run the command, keeping the terminal open afterwards
alacritty -e bash -lc "$CMD_STR; echo; echo 'Press ENTER to close...'; read -r" &

exit 0
