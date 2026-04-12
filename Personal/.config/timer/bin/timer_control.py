#!/usr/bin/env python3
"""
Remote timer client – communicates with the Flask server.
Usage:
  timer_control.py status [--cached]
  timer_control.py start <task_name> <mode>
  timer_control.py switch_mode
  timer_control.py complete
  timer_control.py stop
  timer_control.py break_start <minutes>
  timer_control.py break_end
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error

CONF_FILE = os.path.expanduser("~/.config/timer/server.conf")
STATE_FILE = os.path.expanduser("~/.config/timer/timer_state.json")

def get_server_url():
    if not os.path.exists(CONF_FILE):
        sys.stderr.write(f"Config file {CONF_FILE} not found\n")
        sys.exit(1)
    with open(CONF_FILE) as f:
        for line in f:
            if line.startswith("SERVER_URL="):
                return line.strip().split("=", 1)[1].strip('"').strip("'")
    sys.stderr.write("SERVER_URL not defined in config\n")
    sys.exit(1)

BASE_URL = get_server_url()

def request(endpoint, method="GET", data=None):
    url = f"{BASE_URL}{endpoint}"
    req = urllib.request.Request(url, method=method)
    if data is not None:
        req.add_header("Content-Type", "application/json")
        req.data = json.dumps(data).encode("utf-8")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.load(resp)
    except urllib.error.URLError as e:
        sys.stderr.write(f"Server unreachable: {e}\n")
        sys.exit(1)
    except json.JSONDecodeError:
        sys.stderr.write("Invalid JSON response from server\n")
        sys.exit(1)

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)

def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"active": False}

def main():
    if len(sys.argv) < 2:
        print("Usage: timer_control.py <command> [args...]", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "status":
        cached = "--cached" in sys.argv
        if cached:
            state = load_state()
            print(json.dumps(state))
        else:
            try:
                data = request("/status")
                save_state(data)
                print(json.dumps(data))
            except SystemExit:
                # Server unreachable – fallback to cached
                state = load_state()
                print(json.dumps(state))

    elif cmd == "start":
        if len(sys.argv) < 4:
            sys.stderr.write("Usage: timer_control.py start <task_name> <mode>\n")
            sys.exit(1)
        task_name = sys.argv[2]
        mode = sys.argv[3]
        data = request("/start", method="POST", data={
            "task_name": task_name,
            "mode": mode,
            "timer_type": "free"
        })
        print(json.dumps(data))

    elif cmd == "switch_mode":
        data = request("/mode/switch", method="POST", data={"mode": ""})
        print(json.dumps(data))

    elif cmd == "complete":
        data = request("/complete", method="POST")
        print(json.dumps(data))

    elif cmd == "stop":
        data = request("/stop", method="POST")
        print(json.dumps(data))

    elif cmd == "break_start":
        if len(sys.argv) < 3:
            sys.stderr.write("Usage: timer_control.py break_start <minutes>\n")
            sys.exit(1)
        minutes = int(sys.argv[2])
        data = request("/break/start", method="POST", data={"duration": minutes})
        print(json.dumps(data))

    elif cmd == "break_end":
        data = request("/break/end", method="POST")
        print(json.dumps(data))

    else:
        sys.stderr.write(f"Unknown command: {cmd}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
