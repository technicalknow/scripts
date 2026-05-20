#!/bin/zsh

echo "any song in your mind ?? "
read -r  QUERY
yt-dlp --get-id "ytsearch1:${QUERY}" | sed 's_^_https://youtu.be/_' | xargs -I {} mpv --no-video {}

