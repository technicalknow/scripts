#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: share <file_path>"
    exit 1
fi
response=$(curl -s -F "file=@$1" https://0x0.st)
echo $response
