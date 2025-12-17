import subprocess
import time
import tkinter as tk
from tkinter import ttk

def start_typing():
    text = text_box.get("1.0", tk.END).rstrip("\n")
    delay = float(delay_entry.get())
    key_delay = int(key_delay_entry.get())

    status.set(f"Waiting {delay} seconds...")
    root.update()

    time.sleep(delay)

    status.set("Typing...")
    root.update()

    for line in text.splitlines():
        subprocess.run([
            "xdotool",
            "type",
            "--delay", str(key_delay),
            "--clearmodifiers",
            "--", line
        ])
        subprocess.run([
            "xdotool",
            "key",
            "--clearmodifiers",
            "Return"
        ])

    status.set("Done.")

root = tk.Tk()
root.title("KVM Command Typer")

frame = ttk.Frame(root, padding=10)
frame.grid()

ttk.Label(frame, text="Command / Script:").grid(column=0, row=0, sticky="w")

text_box = tk.Text(frame, width=100, height=20)
text_box.grid(column=0, row=1, columnspan=4, pady=5)

ttk.Label(frame, text="Start delay (seconds):").grid(column=0, row=2, sticky="e")
delay_entry = ttk.Entry(frame, width=10)
delay_entry.insert(0, "5")
delay_entry.grid(column=1, row=2, sticky="w")

ttk.Label(frame, text="Key delay (ms):").grid(column=2, row=2, sticky="e")
key_delay_entry = ttk.Entry(frame, width=10)
key_delay_entry.insert(0, "40")
key_delay_entry.grid(column=3, row=2, sticky="w")

ttk.Button(frame, text="Start Typing", command=start_typing).grid(
    column=0, row=3, columnspan=4, pady=10
)

status = tk.StringVar(value="Idle.")
ttk.Label(frame, textvariable=status).grid(column=0, row=4, columnspan=4)

root.mainloop()
