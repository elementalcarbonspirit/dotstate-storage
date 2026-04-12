#!/usr/bin/env bash
while true; do
    nid=$(cat /tmp/.timer_notif_id 2>/dev/null)
    if [[ -n "$nid" && "$nid" != "0" ]]; then
        python3 ~/.config/i3/scripts/timer_client.py status
    fi
    sleep 30
done
