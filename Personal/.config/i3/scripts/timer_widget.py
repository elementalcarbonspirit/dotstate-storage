#!/usr/bin/env python3
import tkinter as tk
import requests
import threading
import os

SERVER = "http://140.245.120.119:5000"

BG      = "#2E3440"
BG2     = "#3B4252"
BG3     = "#434C5E"
BLUE    = "#88C0D0"
GREEN   = "#A3BE8C"
YELLOW  = "#EBCB8B"
RED     = "#BF616A"
FG      = "#D8DEE9"
FG_DIM  = "#4C566A"

FONT       = "JetBrainsMono Nerd Font"
FONT_TIMER = (FONT, 22, "bold")
FONT_TASK  = (FONT, 11)
FONT_MODE  = (FONT, 10)
FONT_BTN   = (FONT, 10)
FONT_SMALL = (FONT, 9)

def fmt(s):
    h = int(s // 3600)
    m = int((s % 3600) // 60)
    sc = int(s % 60)
    return f"{h}:{m:02d}:{sc:02d}" if h else f"{m:02d}:{sc:02d}"

class TimerWidget:
    def __init__(self, root):
        self.root = root
        self.data = {"active": False}
        self.expanded = False
        self.collapse_after = None
        self.break_expanded = False

        root.overrideredirect(True)
        root.attributes("-topmost", True)
        root.attributes("-alpha", 0.93)
        root.configure(bg=BG)

        # single horizontal container
        self.bar = tk.Frame(root, bg=BG, pady=6)
        self.bar.pack(fill="x")

        # ── collapsed: just timer ──────────────────────────
        self.f_timer = tk.Frame(self.bar, bg=BG, padx=14)
        self.f_timer.pack(side="right")

        self.lbl_timer = tk.Label(
            self.f_timer, text="--:--",
            font=FONT_TIMER, fg=BLUE, bg=BG
        )
        self.lbl_timer.pack()

        # ── expanded left side ────────────────────────────
        self.f_expanded = tk.Frame(self.bar, bg=BG)

        # mode icon + task name + done check
        self.f_top = tk.Frame(self.f_expanded, bg=BG, padx=12)
        self.f_top.pack(side="top", fill="x")

        self.lbl_icon = tk.Label(self.f_top, text="", font=(FONT, 13),
                                  fg=BLUE, bg=BG)
        self.lbl_icon.pack(side="left", padx=(0, 6))

        self.lbl_task = tk.Label(self.f_top, text="",
                                  font=FONT_TASK, fg=FG, bg=BG)
        self.lbl_task.pack(side="left")

        self.btn_done = None  # created after f_btns

        # mode label
        self.lbl_mode = tk.Label(self.f_expanded, text="",
                                  font=FONT_MODE, fg=FG_DIM, bg=BG, padx=12)
        self.lbl_mode.pack(side="top", anchor="w")

        # action buttons row
        self.f_btns = tk.Frame(self.f_expanded, bg=BG, padx=10, pady=2)
        self.f_btns.pack(side="top", anchor="w")

        self.btn_switch = self._btn(self.f_btns, "", BLUE, self.switch_mode)
        self.btn_switch.pack(side="left", padx=(0, 6))

        self.btn_break = self._btn(self.f_btns, " Break", YELLOW, self.toggle_break)
        self.btn_break.pack(side="left", padx=(0, 6))

        self.btn_resume = self._btn(self.f_btns, " Resume", GREEN, self.end_break)
        self.btn_resume.pack(side="left", padx=(0, 6))

        self.btn_new = self._btn(self.f_btns, " New task", FG_DIM, self.show_new_task)
        self.btn_new.pack(side="left", padx=(0, 6))

        self.btn_done = self._btn(self.f_btns, " Done", GREEN, self.complete)

        # break submenu
        self.f_break = tk.Frame(self.f_expanded, bg=BG2, padx=8, pady=4)
        self.btn_b5  = self._btn(self.f_break, "5m",     YELLOW, lambda: self.start_break(5))
        self.btn_b5.pack(side="left", padx=3)
        self.btn_b10 = self._btn(self.f_break, "10m",    YELLOW, lambda: self.start_break(10))
        self.btn_b10.pack(side="left", padx=3)
        self.btn_bc  = self._btn(self.f_break, "custom", YELLOW, self.custom_break)
        self.btn_bc.pack(side="left", padx=3)

        # top border line (color matches mode)
        self.border = tk.Frame(root, height=2, bg=BLUE)
        self.border.pack(fill="x", side="top", before=self.bar)

        # hover bindings
        self._bind_hover(root)

        self.position()
        self.poll()

    def _btn(self, parent, text, color, cmd):
        b = tk.Label(parent, text=text, font=FONT_BTN,
                     fg=color, bg=BG2, padx=8, pady=3,
                     cursor="hand2", relief="flat")
        b.bind("<Button-1>", lambda e: cmd())
        b.bind("<Enter>", lambda e: b.config(bg=BG3))
        b.bind("<Leave>", lambda e: b.config(bg=BG2))
        return b

    def _bind_hover(self, w):
        w.bind("<Enter>", self.on_enter, add="+")
        w.bind("<Leave>", self.on_leave, add="+")
        for child in w.winfo_children():
            self._bind_hover(child)

    def on_enter(self, e):
        if self.collapse_after:
            self.root.after_cancel(self.collapse_after)
            self.collapse_after = None
        if not self.expanded:
            self.expanded = True
            self.f_expanded.pack(side="left", before=self.f_timer)
            self.root.update_idletasks()
            self.position()

    def on_leave(self, e):
        if self.collapse_after:
            self.root.after_cancel(self.collapse_after)
        self.collapse_after = self.root.after(1500, self.collapse)

    def collapse(self):
        if self.break_expanded:
            self.f_break.pack_forget()
            self.break_expanded = False
        self.expanded = False
        self.f_expanded.pack_forget()
        self.root.update_idletasks()
        self.position()

    def position(self):
        self.root.update_idletasks()
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        w  = self.root.winfo_reqwidth()
        h  = self.root.winfo_reqheight()
        # flush bottom-right, above polybar (32px)
        self.root.geometry(f"{w}x{h}+{sw - w}+{sh - h - 32}")
        self.root.after(300, lambda: os.system(f"xdotool search --name timer windowmove {sw - w} {sh - h - 32}"))

    def poll(self):
        try:
            r = requests.get(f"{SERVER}/status", timeout=2)
            self.data = r.json()
        except:
            self.data = {"active": False, "error": True}
        self.update_ui()
        self.root.after(1000, self.poll)

    def update_ui(self):
        d = self.data

        if not d.get("active"):
            self.lbl_timer.config(text="--:--", fg=FG_DIM)
            self.border.config(bg=FG_DIM)
            if self.expanded:
                self.lbl_icon.config(text="")
                self.lbl_task.config(text="no active session")
                self.lbl_mode.config(text="")
                self.btn_done.config(text="")
                self.btn_switch.pack_forget()
                self.btn_break.pack_forget()
                self.btn_resume.pack_forget()
                self.btn_new.pack(side="left")
            return

        if d.get("on_break"):
            t     = fmt(d["break_elapsed"])
            color = YELLOW
            icon  = ""
            mode  = "on break"
            self.btn_resume.pack(side="left", padx=(0,6))
            self.btn_break.pack_forget()
            self.btn_switch.pack_forget()
            self.btn_done.config(text="")
            self.btn_new.pack_forget()
        else:
            t     = fmt(d["elapsed"])
            color = BLUE if d["mode"] == "writing" else GREEN
            icon  = "" if d["mode"] == "writing" else ""
            mode  = d["mode"]
            switch_text = " → Formatting" if d["mode"] == "writing" else " → Writing"
            self.btn_switch.config(text=switch_text, fg=color)
            self.btn_switch.pack(side="left", padx=(0,6))
            self.btn_break.pack(side="left", padx=(0,6))
            self.btn_resume.pack_forget()
            self.btn_done.config(text="", fg=GREEN)
            self.btn_done.pack(side="left", padx=(0,6))
            self.btn_new.pack(side="left", padx=(0,6))

        self.lbl_timer.config(text=t, fg=color)
        self.border.config(bg=color)
        self.lbl_icon.config(text=icon, fg=color)
        self.lbl_task.config(text=d.get("task_name",""))
        self.lbl_mode.config(text=mode, fg=FG_DIM)
        self.position()

    def switch_mode(self):
        d = self.data
        if not d.get("active") or d.get("on_break"):
            return
        new_mode = "formatting" if d["mode"] == "writing" else "writing"
        threading.Thread(target=lambda: requests.post(
            f"{SERVER}/mode/switch", json={"mode": new_mode}
        )).start()

    def toggle_break(self):
        if self.break_expanded:
            self.f_break.pack_forget()
            self.break_expanded = False
        else:
            self.f_break.pack(side="top", fill="x", pady=(2,0))
            self._bind_hover(self.f_break)
            self.break_expanded = True
        self.position()

    def start_break(self, mins):
        self.f_break.pack_forget()
        self.break_expanded = False
        threading.Thread(target=lambda: requests.post(
            f"{SERVER}/break/start", json={"duration": mins}
        )).start()

    def custom_break(self):
        # replace break buttons with inline entry
        for w in self.f_break.winfo_children():
            w.pack_forget()
        tk.Label(self.f_break, text="min:", font=FONT_SMALL,
                 fg=FG_DIM, bg=BG2).pack(side="left", padx=4)
        e = tk.Entry(self.f_break, width=4, bg=BG, fg=FG,
                     insertbackground=FG, relief="flat", font=FONT_BTN)
        e.pack(side="left", padx=4)
        e.focus_set()
        def submit(ev=None):
            val = e.get().strip()
            if val.isdigit():
                self.start_break(int(val))
            else:
                # restore buttons
                for w in self.f_break.winfo_children():
                    w.destroy()
                self.btn_b5  = self._btn(self.f_break, "5m",     YELLOW, lambda: self.start_break(5))
                self.btn_b5.pack(side="left", padx=3)
                self.btn_b10 = self._btn(self.f_break, "10m",    YELLOW, lambda: self.start_break(10))
                self.btn_b10.pack(side="left", padx=3)
                self.btn_bc  = self._btn(self.f_break, "custom", YELLOW, self.custom_break)
                self.btn_bc.pack(side="left", padx=3)
        e.bind("<Return>", submit)
        e.bind("<Escape>", lambda ev: submit())

    def end_break(self):
        threading.Thread(target=lambda: requests.post(
            f"{SERVER}/break/end"
        )).start()

    def complete(self):
        threading.Thread(target=lambda: requests.post(
            f"{SERVER}/complete"
        )).start()

    def show_new_task(self):
        win = tk.Toplevel(self.root)
        win.configure(bg=BG)
        win.attributes("-topmost", True)
        win.overrideredirect(True)
        win.resizable(False, False)

        self.root.update_idletasks()
        x = self.root.winfo_x()
        y = self.root.winfo_y() - 180
        win.geometry(f"320x170+{x}+{y}")

        tk.Label(win, text="task name", font=FONT_SMALL,
                 fg=FG_DIM, bg=BG).pack(anchor="w", padx=14, pady=(12,0))
        entry = tk.Entry(win, bg=BG2, fg=FG, insertbackground=FG,
                         relief="flat", font=FONT_TASK, width=34)
        entry.pack(padx=14, pady=4, fill="x")
        entry.focus()

        mode_var = tk.StringVar(value="writing")
        type_var = tk.StringVar(value="free")

        rf = tk.Frame(win, bg=BG)
        rf.pack(fill="x", padx=14, pady=4)

        for text, val, color in [(" Writing","writing",BLUE),
                                   (" Formatting","formatting",GREEN)]:
            tk.Radiobutton(rf, text=text, variable=mode_var, value=val,
                           fg=color, bg=BG, selectcolor=BG2,
                           activebackground=BG,
                           font=FONT_SMALL).pack(side="left", padx=4)

        tf = tk.Frame(win, bg=BG)
        tf.pack(fill="x", padx=14, pady=2)
        for text, val, color in [("free","free",FG),
                                   ("🍅 pomodoro","pomodoro",YELLOW)]:
            tk.Radiobutton(tf, text=text, variable=type_var, value=val,
                           fg=color, bg=BG, selectcolor=BG2,
                           activebackground=BG,
                           font=FONT_SMALL).pack(side="left", padx=4)

        bf = tk.Frame(win, bg=BG)
        bf.pack(fill="x", padx=14, pady=8)

        def submit(ev=None):
            task = entry.get().strip()
            if not task:
                return
            threading.Thread(target=lambda: requests.post(
                f"{SERVER}/start", json={
                    "task_name": task,
                    "mode": mode_var.get(),
                    "timer_type": type_var.get()
                }
            )).start()
            win.destroy()

        def cancel(ev=None):
            win.destroy()

        tk.Label(bf, text="start", font=FONT_BTN,
                 fg=BG, bg=BLUE, padx=12, pady=4,
                 cursor="hand2").pack(side="left")
        bf.winfo_children()[0].bind("<Button-1>", submit)

        tk.Label(bf, text="cancel", font=FONT_BTN,
                 fg=FG_DIM, bg=BG2, padx=12, pady=4,
                 cursor="hand2").pack(side="left", padx=8)
        bf.winfo_children()[1].bind("<Button-1>", cancel)

        win.bind("<Return>", submit)
        win.bind("<Escape>", cancel)

if __name__ == "__main__":
    root = tk.Tk()
    root.title("timer")
    TimerWidget(root)
    root.mainloop()
