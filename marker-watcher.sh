#!/bin/bash

WATCH_DIR="/workspace/tmp/notifier"

# Check if inotifywait is available
if command -v inotifywait &> /dev/null; then
    echo "Using inotifywait to watch $WATCH_DIR"
    inotifywait -m -e create --format '%f' "$WATCH_DIR" | while read -r file; do
        notify-send "Marker file created" "$file"
    done
else
    echo "inotifywait not found, using polling fallback"
    mkdir -p "$WATCH_DIR"
    while true; do
        for file in "$WATCH_DIR"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                notify-send "Marker file created" "$filename"
                rm "$file"
            fi
        done
        sleep 2
    done
fi
