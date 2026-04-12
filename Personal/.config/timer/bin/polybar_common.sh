#!/bin/bash
STATE_FILE="$HOME/.config/timer/timer_state.json"
CONTROL="$HOME/.config/timer/bin/timer_control.py"

# Colors (Nord)
COLOR_IDLE="#D8DEE9"
COLOR_WRITING="#A3BE8C"
COLOR_FORMATTING="#81A1C1"
COLOR_BREAK="#EBCB8B"
COLOR_DONE="#BF616A"

format_time() {
  local seconds=${1%.*} # Remove decimal part
  if [ "$seconds" -lt 3600 ]; then
    printf "%02d:%02d" $((seconds / 60)) $((seconds % 60))
  else
    printf "%d:%02d:%02d" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
  fi
}

get_state() {
  $CONTROL status --cached 2>/dev/null
}
