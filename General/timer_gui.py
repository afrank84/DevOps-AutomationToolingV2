import tkinter as tk
from tkinter import ttk

class TimerGUI:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Timer")
        self.root.resizable(False, False)

        # State
        self.total_seconds = 0
        self.remaining_seconds = 0
        self.running = False
        self.paused = False
        self._after_id = None

        # UI
        pad = {"padx": 8, "pady": 6}

        ttk.Label(root, text="Minutes").grid(row=0, column=0, sticky="w", **pad)
        ttk.Label(root, text="Seconds").grid(row=0, column=1, sticky="w", **pad)

        self.min_var = tk.StringVar(value="5")
        self.sec_var = tk.StringVar(value="0")

        self.min_entry = ttk.Entry(root, width=8, textvariable=self.min_var)
        self.sec_entry = ttk.Entry(root, width=8, textvariable=self.sec_var)
        self.min_entry.grid(row=1, column=0, sticky="w", **pad)
        self.sec_entry.grid(row=1, column=1, sticky="w", **pad)

        self.display_var = tk.StringVar(value="00:00")
        self.display = ttk.Label(root, textvariable=self.display_var, font=("TkDefaultFont", 24))
        self.display.grid(row=2, column=0, columnspan=2, sticky="ew", **pad)

        self.status_var = tk.StringVar(value="Ready")
        self.status = ttk.Label(root, textvariable=self.status_var)
        self.status.grid(row=3, column=0, columnspan=2, sticky="w", **pad)

        self.start_btn = ttk.Button(root, text="Start", command=self.start)
        self.pause_btn = ttk.Button(root, text="Pause", command=self.toggle_pause, state="disabled")
        self.reset_btn = ttk.Button(root, text="Reset", command=self.reset, state="disabled")

        self.start_btn.grid(row=4, column=0, sticky="ew", **pad)
        self.pause_btn.grid(row=4, column=1, sticky="ew", **pad)
        self.reset_btn.grid(row=5, column=0, columnspan=2, sticky="ew", **pad)

        root.protocol("WM_DELETE_WINDOW", self.on_close)

    def parse_input_seconds(self) -> int:
        def to_int(s: str) -> int:
            s = s.strip()
            if s == "":
                return 0
            if not s.isdigit():
                raise ValueError("Only whole numbers are allowed.")
            return int(s)

        minutes = to_int(self.min_var.get())
        seconds = to_int(self.sec_var.get())

        if seconds >= 60:
            raise ValueError("Seconds must be 0-59.")

        total = minutes * 60 + seconds
        if total <= 0:
            raise ValueError("Enter a duration greater than 0.")
        return total

    def set_buttons(self, *, start: bool, pause: bool, reset: bool):
        self.start_btn.config(state=("normal" if start else "disabled"))
        self.pause_btn.config(state=("normal" if pause else "disabled"))
        self.reset_btn.config(state=("normal" if reset else "disabled"))

    def update_display(self):
        m = self.remaining_seconds // 60
        s = self.remaining_seconds % 60
        self.display_var.set(f"{m:02d}:{s:02d}")

    def start(self):
        if self.running:
            return
        try:
            self.total_seconds = self.parse_input_seconds()
        except ValueError as e:
            self.status_var.set(f"Error: {e}")
            return

        self.remaining_seconds = self.total_seconds
        self.running = True
        self.paused = False
        self.status_var.set("Running")
        self.set_buttons(start=False, pause=True, reset=True)
        self.update_display()
        self.tick()

    def tick(self):
        if not self.running or self.paused:
            return

        if self.remaining_seconds <= 0:
            self.finish()
            return

        self.remaining_seconds -= 1
        self.update_display()
        self._after_id = self.root.after(1000, self.tick)

    def toggle_pause(self):
        if not self.running:
            return

        if not self.paused:
            self.paused = True
            self.status_var.set("Paused")
            self.pause_btn.config(text="Resume")
            if self._after_id is not None:
                self.root.after_cancel(self._after_id)
                self._after_id = None
        else:
            self.paused = False
            self.status_var.set("Running")
            self.pause_btn.config(text="Pause")
            self.tick()

    def reset(self):
        if self._after_id is not None:
            self.root.after_cancel(self._after_id)
            self._after_id = None

        self.running = False
        self.paused = False
        self.remaining_seconds = 0
        self.update_display()
        self.status_var.set("Ready")
        self.pause_btn.config(text="Pause")
        self.set_buttons(start=True, pause=False, reset=False)

    def finish(self):
        if self._after_id is not None:
            self.root.after_cancel(self._after_id)
            self._after_id = None

        self.running = False
        self.paused = False
        self.remaining_seconds = 0
        self.update_display()
        self.status_var.set("Done")
        self.set_buttons(start=True, pause=False, reset=False)

        # System beep (may vary by OS)
        try:
            self.root.bell()
        except Exception:
            pass

    def on_close(self):
        if self._after_id is not None:
            try:
                self.root.after_cancel(self._after_id)
            except Exception:
                pass
        self.root.destroy()


def main():
    root = tk.Tk()
    # Use ttk themed widgets
    ttk.Style().theme_use("default")
    TimerGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
