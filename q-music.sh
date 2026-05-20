#!/bin/sh
cd ~/Music

fzf | xargs -I {} mpv --no-video {}
