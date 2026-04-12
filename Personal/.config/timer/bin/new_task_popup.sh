#!/bin/bash
CONTROL="$HOME/.config/timer/bin/timer_control.py"

# Nordic color palette
BG="#2E3440"
FG="#D8DEE9"
BTN_BG="#5E81AC"
BTN_FG="#ECEFF4"

# Yad form to enter task name
ENTRY=$(yad --form --title="New Timer Task" \
  --width=400 --height=100 \
  --center --on-top \
  --borders=10 \
  --text="<span foreground='$FG'>Enter task name:</span>" \
  --field="": "" \
  --button="Writing!$BTN_BG!$BTN_FG":0 \
  --button="Formatting!$BTN_BG!$BTN_FG":1 \
  --button="Cancel!$BG!$FG":2 \
  --gtk-theme=Nordic \
  --undecorated \
  --skip-taskbar)

ret=$?
task_name=$(echo "$ENTRY" | cut -d'|' -f1)

if [[ $ret -eq 2 || -z "$task_name" ]]; then
  exit 0
fi

if [[ $ret -eq 0 ]]; then
  mode="writing"
else
  mode="formatting"
fi

# Start session on server
$CONTROL start "$task_name" "$mode" >/dev/null 2>&1
# Force polybar refresh
pkill -SIGRTMIN+8 i3status 2>/dev/null || true # adjust if using different bar
