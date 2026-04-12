#!/bin/bash
SERVER="http://140.245.120.119:5000"
DATA_FILE="$HOME/.config/timer/earnings_cache.txt"

# Helper: fetch from server, fallback to cache
fetch_earnings() {
  resp=$(curl -s --max-time 2 "$SERVER/api/earnings")
  if [[ -n "$resp" ]]; then
    echo "$resp" | jq -r '"TODAY=\(.today)\nMONTHLY=\(.monthly)"' >"$DATA_FILE"
    echo "$resp"
  else
    # Offline – use cache
    source "$DATA_FILE" 2>/dev/null || {
      echo '{"today":0,"monthly":0}'
      return
    }
    echo "{\"today\":$TODAY,\"monthly\":$MONTHLY}"
  fi
}

if [[ "$1" == "click" ]]; then
  # Zenity confirmation
  if zenity --question --title="Add Earnings" --text="Add \$50 to today and monthly total?" --ok-label="+ \$50" --cancel-label="Cancel" --width=300 2>/dev/null; then
    # Send to server
    resp=$(curl -s -X POST "$SERVER/api/earnings/add" -H "Content-Type: application/json" -d '{"amount":50}')
    if [[ -n "$resp" ]]; then
      echo "$resp" | jq -r '"TODAY=\(.today)\nMONTHLY=\(.monthly)"' >"$DATA_FILE"
      notify-send "+$50 added" "Today: \$$(echo "$resp" | jq -r .today) | Month: \$$(echo "$resp" | jq -r .monthly)"
    else
      # Offline fallback
      source "$DATA_FILE" 2>/dev/null || {
        TODAY=0
        MONTHLY=0
      }
      TODAY=$((TODAY + 50))
      MONTHLY=$((MONTHLY + 50))
      echo "TODAY=$TODAY" >"$DATA_FILE"
      echo "MONTHLY=$MONTHLY" >>"$DATA_FILE"
      notify-send "+$50 added (offline)" "Today: \$$TODAY | Month: \$$MONTHLY"
    fi
    polybar-msg hook money 1 2>/dev/null || pkill -SIGUSR1 polybar 2>/dev/null
  fi
  exit 0
fi

# Display
data=$(fetch_earnings)
today=$(echo "$data" | jq -r '.today')
monthly=$(echo "$data" | jq -r '.monthly')
echo "\$$today / \$$monthly"
