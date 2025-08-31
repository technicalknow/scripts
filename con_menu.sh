#!/usr/bin/env bash

# Config file paths — adjust if needed
I3="$HOME/.config/i3/config"
I3STATUS="$HOME/.config/i3status/config"
ROFI="$HOME/.config/rofi/config.rasi"
ALACRITTY="$HOME/.config/alacritty/alacritty.toml"
POLYBAR="$HOME/.config/polybar/config"
PICOM="$HOME/.config/picom/picom.conf"

items=(
  "i3|$I3"
  "i3status|$I3STATUS"
  "rofi|$ROFI"
  "alacritty|$ALACRITTY"
  "polybar|$POLYBAR"
  "picom|$PICOM"
  "Open containing folder (file manager)|$HOME/.config"
  "Quit|__QUIT__"
)

menu_input=""
for item in "${items[@]}"; do
  name="${item%%|*}"
  menu_input+="$name\n"
done

CHOICE=$(printf "%b" "$menu_input" | dmenu -i -l 10 -p "Edit config:")

[ -z "$CHOICE" ] && exit 0
[ "$CHOICE" = "Quit" ] && exit 0

selected_path=""
for item in "${items[@]}"; do
  name="${item%%|*}"
  path="${item#*|}"
  if [ "$name" = "$CHOICE" ]; then
    selected_path="$path"
    break
  fi
done

[ -z "$selected_path" ] && exit 1

if [ "$selected_path" = "$HOME/.config" ]; then
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$selected_path" &
  elif command -v nautilus >/dev/null 2>&1; then
    nautilus "$selected_path" &
  elif command -v thunar >/dev/null 2>&1; then
    thunar "$selected_path" &
  else
    notify-send "No file manager found"
    exit 1
  fi
  exit 0
fi

mkdir -p "$(dirname "$selected_path")"
[ ! -e "$selected_path" ] && touch "$selected_path"

# Force use of xed as the editor (GUI text editor)
if ! command -v xed >/dev/null 2>&1; then
  echo "xed not found in PATH" >&2
  exit 1
fi

xed "$selected_path" &
