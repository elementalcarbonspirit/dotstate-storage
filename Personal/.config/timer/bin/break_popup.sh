#!/bin/bash
CONTROL="$HOME/.config/timer/bin/timer_control.py"

choice=$(echo -e "5 minutes\n10 minutes\n15 minutes\nCustom..." |
  rofi -dmenu -p "Break duration" -theme-str 'window {background: #2E3440;}')

case "$choice" in
"5 minutes") mins=5 ;;
"10 minutes") mins=10 ;;
"15 minutes") mins=15 ;;
"Custom...")
  custom=$(rofi -dmenu -p "Enter minutes:" -theme-str 'window {background: #2E3440;}')
  if [[ "$custom" =~ ^[0-9]+$ ]]; then
    mins=$custom
  else
    exit 0
  fi
  ;;
*) exit 0 ;;
esac

$CONTROL break_start "$mins" >/dev/null 2>&1
