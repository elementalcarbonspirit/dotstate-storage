#!/usr/bin/env bash

LAST_DIR_FILE="$HOME/.config/i3/scripts/.last_screenshot_dir"
DEFAULT_DIR="$HOME/Pictures/Screenshots"

mkdir -p "$DEFAULT_DIR"

# get last saved dir or fall back to default
get_dir() {
    if [[ -f "$LAST_DIR_FILE" ]]; then
        cat "$LAST_DIR_FILE"
    else
        echo "$DEFAULT_DIR"
    fi
}

save_dir=$(get_dir)
filename="screenshot_$(date +%Y-%m-%d_%H%M%S).png"

case "$1" in
    full)
        # Pause/Break — capture full screen, save to last dir
        maim "$save_dir/$filename"
        dunstify "Screenshot saved" "$save_dir/$filename"
        ;;
    pick)
        # Home — ask where to save, remember it
        chosen=$(zenity --file-selection --save \
            --filename="$save_dir/$filename" \
            --title="Save screenshot to..." \
            --file-filter="PNG files | *.png" 2>/dev/null)
        if [[ -n "$chosen" ]]; then
            chosen_dir=$(dirname "$chosen")
            echo "$chosen_dir" > "$LAST_DIR_FILE"
            maim "$chosen"
            dunstify "Screenshot saved" "$chosen"
        fi
        ;;
    region)
        # Print — select region, save to last dir
        maim -s "$save_dir/$filename"
        dunstify "Screenshot saved" "$save_dir/$filename"
        ;;
esac
