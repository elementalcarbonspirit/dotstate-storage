#!/usr/bin/env bash
for iface in eth0 wlan0 usb0 tailscale0; do
    if ip link show "$iface" 2>/dev/null | grep -qE "state (UP|UNKNOWN)"; then
        case "$iface" in
            eth0)       echo "  eth" ;;
            wlan0)      echo "  $(iwgetid -r 2>/dev/null || echo wifi)" ;;
            usb0)       echo "  tether" ;;
            tailscale0) echo "  vpn" ;;
        esac
        exit 0
    fi
done
echo "  offline"
