#!/bin/bash
source "$HOME/.config/timer/bin/polybar_common.sh"

if [[ "$1" == "click" ]]; then
    state=$(get_state)
    active=$(echo "$state" | jq -r '.active // false')
    on_break=$(echo "$state" | jq -r '.on_break // false')
    if [[ "$active" == "true" ]]; then
        if [[ "$on_break" == "true" ]]; then
            # Currently on break – end break
            $CONTROL break_end >/dev/null 2>&1
        else
            # Not on break – start break (show menu)
            $HOME/.config/timer/bin/break_popup.sh
        fi
        # Force state refresh
        $CONTROL status >/dev/null 2>&1
    fi
    exit 0
fi

state=$(get_state)
active=$(echo "$state" | jq -r '.active // false')
if [[ "$active" != "true" ]]; then
    exit 0
fi

on_break=$(echo "$state" | jq -r '.on_break // false')
if [[ "$on_break" == "true" ]]; then
    break_elapsed=$(echo "$state" | jq -r '.break_elapsed // 0')
    time_str=$(format_time "$break_elapsed")
    echo "%{F$COLOR_BREAK}󰑐 $time_str%{F-}"
else
    echo "%{F$COLOR_IDLE}󰑐 Break%{F-}"
fi
