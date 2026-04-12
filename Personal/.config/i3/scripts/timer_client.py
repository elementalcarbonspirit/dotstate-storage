#!/usr/bin/env python3
import requests, sys, time, subprocess, json, os

SERVER = "http://140.245.120.119:5000"
NOTIFICATION_ID_FILE = "/tmp/.timer_notif_id"

def fmt_time(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    if h:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m:02d}:{s:02d}"

def get_notif_id():
    if os.path.exists(NOTIFICATION_ID_FILE):
        return open(NOTIFICATION_ID_FILE).read().strip()
    return "0"

def save_notif_id(nid):
    open(NOTIFICATION_ID_FILE, "w").write(str(nid))

def notify(title, body, actions=None, urgency="normal"):
    cmd = ["dunstify", "-r", get_notif_id(), "-u", urgency,
           "-t", "0", title, body]
    if actions:
        for a in actions:
            cmd += ["-A", a]
    result = subprocess.run(cmd, capture_output=True, text=True)
    save_notif_id(result.stdout.strip() or get_notif_id())
    return result.stdout.strip()

def close_notif():
    nid = get_notif_id()
    if nid and nid != "0":
        subprocess.run(["dunstify", "-C", nid])
        save_notif_id("0")

def show_status():
    try:
        r = requests.get(f"{SERVER}/status", timeout=3)
        data = r.json()
    except:
        notify("Timer", "⚠ Server unreachable", urgency="critical")
        return

    if not data["active"]:
        notify("Timer", "No active session\nUse timer --start to begin")
        return

    elapsed = fmt_time(data["elapsed"])
    task = data["task_name"]
    mode = data["mode"].upper()
    icon = "✍" if data["mode"] == "writing" else "🗂"

    if data["on_break"]:
        brk = fmt_time(data["break_elapsed"])
        body = f"{icon} {mode} — {task}\n⏸ On break: {brk}"
        action = notify(f"⏱ {elapsed}", body, ["end_break,▶ End Break"])
        if action == "end_break":
            requests.post(f"{SERVER}/break/end")
    else:
        body = f"{icon} {mode} — {task}"
        if data["timer_type"] == "pomodoro":
            remaining = max(0, 1500 - data["elapsed"])
            body += f"\n🍅 {fmt_time(remaining)} remaining"
        actions = [
            "break5,☕ 5 min break",
            "break10,🛋 10 min break",
            "breakc,⏱ Custom break",
            "complete,✓ Complete"
        ]
        action = notify(f"⏱ {elapsed}", body, actions)
        handle_action(action, data)

def handle_action(action, data):
    if not action:
        return
    if action == "complete":
        requests.post(f"{SERVER}/complete")
        close_notif()
        notify("Timer", f"✓ Completed: {data['task_name']}", urgency="low")
    elif action == "break5":
        requests.post(f"{SERVER}/break/start", json={"duration": 5})
    elif action == "break10":
        requests.post(f"{SERVER}/break/start", json={"duration": 10})
    elif action == "breakc":
        result = subprocess.run(
            ["zenity", "--entry", "--title=Custom Break", "--text=Minutes:"],
            capture_output=True, text=True
        )
        mins = result.stdout.strip()
        if mins.isdigit():
            requests.post(f"{SERVER}/break/start", json={"duration": int(mins)})

def start_session():
    task = subprocess.run(
        ["zenity", "--entry", "--title=New Task", "--text=Task name:"],
        capture_output=True, text=True
    ).stdout.strip()
    if not task:
        return

    mode = subprocess.run(
        ["zenity", "--list", "--title=Mode", "--text=Select mode:",
         "--column=Mode", "writing", "formatting"],
        capture_output=True, text=True
    ).stdout.strip()
    if not mode:
        return

    timer_type = subprocess.run(
        ["zenity", "--list", "--title=Timer Type", "--text=Select type:",
         "--column=Type", "free", "pomodoro"],
        capture_output=True, text=True
    ).stdout.strip()
    if not timer_type:
        return

    requests.post(f"{SERVER}/start", json={
        "task_name": task,
        "mode": mode,
        "timer_type": timer_type
    })
    show_status()

def toggle():
    nid = get_notif_id()
    if nid and nid != "0":
        close_notif()
        save_notif_id("0")
    else:
        show_status()

cmd = sys.argv[1] if len(sys.argv) > 1 else "toggle"
if cmd == "toggle":    toggle()
elif cmd == "start":   start_session()
elif cmd == "status":  show_status()
elif cmd == "stop":
    requests.post(f"{SERVER}/stop")
    close_notif()
