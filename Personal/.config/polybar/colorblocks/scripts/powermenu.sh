#!/usr/bin/env bash
choice=$(echo -e "  Shutdown\n  Reboot\n  Logout\n  Lock" | rofi -dmenu -theme ~/.config/rofi/nord.rasi -p "Power")
case "$choice" in
    *Shutdown) systemctl poweroff ;;
    *Reboot)   systemctl reboot ;;
    *Logout)   i3-msg exit ;;
    *Lock)     i3lock -c 2E3440 ;;
esac
