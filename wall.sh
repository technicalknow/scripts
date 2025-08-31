#!/bin/zsh

cd ~/Pictures/Wallpapers && ls | sxiv -t -o . | sed 's|^\./||' | xargs -I {} wal -i {}
