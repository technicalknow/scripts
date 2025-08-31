#!/bin/sh

exec fzf | xargs -I {} curl -s -F "file=@{}" https://0x0.st
