#!/usr/bin/env bash
# Toggles a pinned kitty terminal running an AI CLI, kept alive on a Hyprland
# special workspace so the session persists across show/hide for the whole
# login session.
#
# The command run inside is configurable from Settings > General > AI Terminal
# (persisted as "aiTerminalCmd" in settings.json), defaulting to "claude".

SETTINGS_JSON="$HOME/.config/hypr/settings.json"
CMD=$(jq -r '.aiTerminalCmd // "claude"' "$SETTINGS_JSON" 2>/dev/null)
if [ -z "$CMD" ] || [ "$CMD" = "null" ]; then
    CMD="claude"
fi

CLASS="ai-terminal"
SPECIAL="aiterm"

exists() {
    hyprctl clients -j 2>/dev/null | jq -e --arg c "$CLASS" '[.[] | select(.class==$c)] | length > 0' >/dev/null
}

case "$1" in
    status)
        if exists; then echo '{"running": true}'; else echo '{"running": false}'; fi
        ;;

    *)
        if exists; then
            hyprctl dispatch togglespecialworkspace "$SPECIAL"
        else
            kitty --class "$CLASS" -e bash -c "$CMD; exec bash" &
            for _ in $(seq 1 50); do
                sleep 0.1
                if exists; then
                    hyprctl dispatch togglespecialworkspace "$SPECIAL"
                    break
                fi
            done
        fi
        ;;
esac
