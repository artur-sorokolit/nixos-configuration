#!/usr/bin/env bash

# State file to remember the last Cyrillic layout (1 = ua, 2 = ru)
STATE_FILE="/tmp/last_cyrillic_layout"
if [ ! -f "$STATE_FILE" ]; then
    echo "1" > "$STATE_FILE"
fi

LAST_CYRILLIC=$(cat "$STATE_FILE")
CURRENT_LAYOUT=$(hyprctl devices -j | jq '.keyboards[] | select(.main == true) | .active_layout_index')

# Get all keyboard names to switch them all at once
keyboards=$(hyprctl devices -j | jq -r '.keyboards[].name')

switch_to() {
    local target_id=$1
    for kb in $keyboards; do
        hyprctl switchxkblayout "$kb" "$target_id" >/dev/null 2>&1
    done
}

case "$1" in
    "toggle-group")
        # Alt+Shift: toggle between US (0) and last active Cyrillic (UA=1 or RU=2)
        if [ "$CURRENT_LAYOUT" -eq 0 ]; then
            switch_to "$LAST_CYRILLIC"
        else
            echo "$CURRENT_LAYOUT" > "$STATE_FILE"
            switch_to 0
        fi
        ;;
    "toggle-cyrillic")
        # Ctrl+Shift: toggle between UA (1) and RU (2), but only if we are not in US (0)
        if [ "$CURRENT_LAYOUT" -ne 0 ]; then
            if [ "$CURRENT_LAYOUT" -eq 1 ]; then
                switch_to 2
                echo "2" > "$STATE_FILE"
            else
                switch_to 1
                echo "1" > "$STATE_FILE"
            fi
        fi
        ;;
esac
