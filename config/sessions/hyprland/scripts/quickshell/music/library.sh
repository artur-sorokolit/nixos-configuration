#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "music"

MUSIC_DIR="$HOME/Videos"
PID_FILE="$QS_RUN_MUSIC/local_player.pid"

case "$1" in
    list)
        find "$MUSIC_DIR" -maxdepth 1 -iname "*.mp3" -printf "%f\n" 2>/dev/null | sort | jq -R -s -c 'split("\n") | map(select(length > 0))'
        ;;

    play)
        track="$2"
        target="$MUSIC_DIR/$track"
        [ -f "$target" ] || exit 0

        if [ -f "$PID_FILE" ]; then
            old_pid=$(cat "$PID_FILE")
            if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
                kill "$old_pid" 2>/dev/null
            fi
            rm -f "$PID_FILE"
        fi

        setsid mpv --no-video "$target" >/dev/null 2>&1 < /dev/null &
        echo $! > "$PID_FILE"
        disown
        ;;
esac
