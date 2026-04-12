#!/bin/bash
source "$HOME/.config/timer/bin/polybar_common.sh"

if [[ "$1" == "click" ]]; then
    state=$(get_state)
    active=$(echo "$state" | jq -r '.active // false')
    if [[ "$active" == "true" ]]; then
        # Toggle mode only if not on break
        on_break=$(echo "$state" | jq -r '.on_break // false')
        if [[ "$on_break" != "true" ]]; then
            $CONTROL switch_mode >/dev/null 2>&1
            $CONTROL status >/dev/null 2>&1
        fi
    else
        $HOME/.config/timer/bin/new_task_popup.sh
    fi
    exit 0
fi

state=$(get_state)
active=$(echo "$state" | jq -r '.active // false')

if [[ "$active" != "true" ]]; then
    echo "%{F$COLOR_IDLE}󰏫  New Task%{F-}"
    exit 0
fi

elapsed=$(echo "$state" | jq -r '.elapsed // 0')
on_break=$(echo "$state" | jq -r '.on_break // false')
mode=$(echo "$state" | jq -r '.mode // "writing"')

if [[ "$on_break" == "true" ]]; then
    # During break, show "Break" text (break module shows time)
    echo "%{F$COLOR_BREAK}⏸ On Break%{F-}"
else
    time_str=$(format_time "$elapsed")
    if [[ "$mode" == "writing" ]]; then
        mode_color="$COLOR_WRITING"
        mode_icon="W"
    else
        mode_color="$COLOR_FORMATTING"
        mode_icon="F"
    fi
    echo "%{F-}󱫋 $time_str %{F$mode_color}[$mode_icon]%{F-}"
fi
