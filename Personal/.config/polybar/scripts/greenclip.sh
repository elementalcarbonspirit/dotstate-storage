#!/bin/bash
GREENCLIP="/home/jellyjam/.local/bin/greenclip"

# Ensure the daemon is running
if ! pgrep -x "greenclip" > /dev/null; then
    $GREENCLIP daemon > /dev/null 2>&1 &
fi

# Pass the action (toggle, print, clear, etc.) to greenclip
$GREENCLIP "$1" 2>/dev/null
