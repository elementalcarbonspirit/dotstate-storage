#!/bin/bash
source "$HOME/.config/timer/bin/polybar_common.sh"

if [[ "$1" == "click" ]]; then
  state=$(get_state)
  active=$(echo "$state" | jq -r '.active // false')
  if [[ "$active" == "true" ]]; then
    $CONTROL complete >/dev/null 2>&1
    # Force state refresh
    $CONTROL status >/dev/null 2>&1
  fi
  exit 0
fi

state=$(get_state)
active=$(echo "$state" | jq -r '.active // false')
if [[ "$active" == "true" ]]; then
  echo "%{F$COLOR_DONE}󰄬 Done%{F-}"
fi
