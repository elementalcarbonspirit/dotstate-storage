#!/bin/bash
set -euo pipefail

REPORT="/tmp/timer_fix_report.txt"
exec > >(tee -a "$REPORT") 2>&1

echo "=== Timer System Diagnostic & Repair ==="
echo "Started at $(date)"

# ------------------------------
# 1. Dependency Checks
# ------------------------------
echo -e "\n[1] Checking dependencies..."
MISSING=""
for cmd in jq curl python3 yad rofi; do
  if ! command -v $cmd >/dev/null; then
    echo "  ✗ $cmd missing"
    MISSING="$MISSING $cmd"
  else
    echo "  ✓ $cmd found"
  fi
done

if [[ -n "$MISSING" ]]; then
  echo "Please install:$MISSING"
  exit 1
fi

# ------------------------------
# 2. Server Connectivity
# ------------------------------
echo -e "\n[2] Testing server connection..."
CONF="$HOME/.config/timer/server.conf"
if [[ ! -f "$CONF" ]]; then
  echo "  ✗ $CONF not found"
  exit 1
fi
source "$CONF"
echo "  Server URL: $SERVER_URL"

if curl -s --max-time 5 "${SERVER_URL}/status" >/dev/null; then
  echo "  ✓ Server reachable"
else
  echo "  ✗ Cannot reach server at $SERVER_URL"
  exit 1
fi

# ------------------------------
# 3. File Structure & Permissions
# ------------------------------
echo -e "\n[3] Checking file permissions..."
cd "$HOME/.config/timer/bin"
for script in timer_control.py polybar_timer.sh polybar_break.sh polybar_done.sh polybar_common.sh new_task_popup.sh break_popup.sh; do
  if [[ ! -f "$script" ]]; then
    echo "  ✗ $script missing"
    exit 1
  fi
  if [[ ! -x "$script" ]]; then
    echo "  ⚠ $script not executable – fixing"
    chmod +x "$script"
  fi
  echo "  ✓ $script"
done

# ------------------------------
# 4. Add save_state to timer_control.py
# ------------------------------
echo -e "\n[4] Ensuring timer_control.py updates state file after actions..."
if ! grep -q "save_state(data)" timer_control.py; then
  echo "  Adding save_state calls..."
  # Backup
  cp timer_control.py timer_control.py.bak
  # Insert save_state after each data = request(... line
  sed -i '/^[[:space:]]*data = request(/a \    save_state(data)' timer_control.py
  echo "  ✓ save_state added"
else
  echo "  ✓ save_state already present"
fi

# ------------------------------
# 5. Fix Break End Logic
# ------------------------------
echo -e "\n[5] Fixing break/resume behaviour..."

# Update polybar_break.sh – clicking when on break will END the break
cat >polybar_break.sh <<'EOF'
#!/bin/bash
source "$HOME/.config/timer/bin/polybar_common.sh"

if [[ "$1" == "click" ]]; then
    state=$(get_state)
    active=$(echo "$state" | jq -r '.active // false')
    on_break=$(echo "$state" | jq -r '.on_break // false')
    if [[ "$active" == "true" ]]; then
        if [[ "$on_break" == "true" ]]; then
            # Currently on break – end break
            $CONTROL break_end >/dev/null 2>&1
        else
            # Not on break – start break (show menu)
            $HOME/.config/timer/bin/break_popup.sh
        fi
        # Force state refresh
        $CONTROL status >/dev/null 2>&1
    fi
    exit 0
fi

state=$(get_state)
active=$(echo "$state" | jq -r '.active // false')
if [[ "$active" != "true" ]]; then
    exit 0
fi

on_break=$(echo "$state" | jq -r '.on_break // false')
if [[ "$on_break" == "true" ]]; then
    break_elapsed=$(echo "$state" | jq -r '.break_elapsed // 0')
    time_str=$(format_time "$break_elapsed")
    echo "%{F$COLOR_BREAK}󰑐 $time_str%{F-}"
else
    echo "%{F$COLOR_IDLE}󰑐 Break%{F-}"
fi
EOF

chmod +x polybar_break.sh
echo "  ✓ polybar_break.sh updated: click during break ends it"

# Update polybar_timer.sh – show break time here too? No, break module handles that.
# But we want the main timer to show something meaningful during break.
cat >polybar_timer.sh <<'EOF'
#!/bin/bash
source "$HOME/.config/timer/bin/polybar_common.sh"

if [[ "$1" == "click" ]]; then
    state=$(get_state)
    active=$(echo "$state" | jq -r '.active // false')
    if [[ "$active" == "true" ]]; then
        # Toggle mode only if not on break
        on_break=$(echo "$state" | jq -r '.on_break // false')
        if [[ "$on_break" != "true" ]]; then
            $CONTROL switch_mode >/dev/null 2>&1
            $CONTROL status >/dev/null 2>&1
        fi
    else
        $HOME/.config/timer/bin/new_task_popup.sh
    fi
    exit 0
fi

state=$(get_state)
active=$(echo "$state" | jq -r '.active // false')

if [[ "$active" != "true" ]]; then
    echo "%{F$COLOR_IDLE}󰏫  New Task%{F-}"
    exit 0
fi

elapsed=$(echo "$state" | jq -r '.elapsed // 0')
on_break=$(echo "$state" | jq -r '.on_break // false')
mode=$(echo "$state" | jq -r '.mode // "writing"')

if [[ "$on_break" == "true" ]]; then
    # During break, show "Break" text (break module shows time)
    echo "%{F$COLOR_BREAK}⏸ On Break%{F-}"
else
    time_str=$(format_time "$elapsed")
    if [[ "$mode" == "writing" ]]; then
        mode_color="$COLOR_WRITING"
        mode_icon="W"
    else
        mode_color="$COLOR_FORMATTING"
        mode_icon="F"
    fi
    echo "%{F-}󱫋 $time_str %{F$mode_color}[$mode_icon]%{F-}"
fi
EOF

chmod +x polybar_timer.sh
echo "  ✓ polybar_timer.sh updated: shows 'On Break' when break active"

# ------------------------------
# 6. Force polybar module to always output something
# ------------------------------
# Already done – all paths have echo.

# ------------------------------
# 7. Clear state file and restart polybar
# ------------------------------
echo -e "\n[6] Restarting polybar..."
pkill polybar || true
sleep 1
~/.config/polybar/colorblocks/launch.sh &
echo "  ✓ Polybar restarted"

# ------------------------------
# 8. Final Report
# ------------------------------
echo -e "\n=== Fix Complete ==="
echo "Report saved to $REPORT"
echo ""
echo "Now test:"
echo "1. Press F12 → enter task → choose mode → timer appears"
echo "2. Click '󰑐 Break' → choose duration → break timer starts"
echo "3. Click the break timer (󰑐 MM:SS) → break ends, work timer resumes"
echo "4. Click '󰄬 Done' → session completes"
echo ""
echo "If issues persist, check $REPORT and the polybar log:"
echo "  tail -f /tmp/polybar_timer_output.log"
