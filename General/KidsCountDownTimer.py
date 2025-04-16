import tkinter as tk
from tkinter import messagebox, simpledialog
import csv
from datetime import datetime, timedelta
import time
import threading

# Master time in seconds (e.g., 5 hours)
MASTER_TIME_TOTAL = 5 * 60 * 60
MASTER_PASSWORD = "parent123"

class TaskTimerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Kid Task Timer")

        self.master_time_remaining = MASTER_TIME_TOTAL
        self.task_running = False
        self.task_paused = False
        self.task_thread = None
        self.task_seconds = 0

        self.create_widgets()
        self.update_master_time_label()

    def create_widgets(self):
        # Master Time Bank Display
        self.master_time_label = tk.Label(self.root, text="Master Time: 00:00:00", font=("Arial", 12, "bold"))
        self.master_time_label.pack(pady=5)

        self.task_name_entry = tk.Entry(self.root, width=30)
        self.task_name_entry.insert(0, "Enter task name")
        self.task_name_entry.pack(pady=5)

        self.time_entry = tk.Entry(self.root, width=30)
        self.time_entry.insert(0, "Enter time in minutes")
        self.time_entry.pack(pady=5)

        self.use_master_time = tk.IntVar()
        self.master_time_check = tk.Checkbutton(self.root, text="Deduct from Master Time", variable=self.use_master_time)
        self.master_time_check.pack(pady=5)

        self.timer_label = tk.Label(self.root, text="00:00:00", font=("Arial", 24))
        self.timer_label.pack(pady=10)

        self.start_button = tk.Button(self.root, text="Start Task", command=self.start_task)
        self.start_button.pack(pady=2)

        self.pause_button = tk.Button(self.root, text="Pause", command=self.pause_task, state=tk.DISABLED)
        self.pause_button.pack(pady=2)

        self.resume_button = tk.Button(self.root, text="Resume", command=self.resume_task, state=tk.DISABLED)
        self.resume_button.pack(pady=2)

        self.reset_master_button = tk.Button(self.root, text="Reset Master Time", command=self.reset_master_time)
        self.reset_master_button.pack(pady=10)

    def update_master_time_label(self):
        hours, remainder = divmod(self.master_time_remaining, 3600)
        minutes, seconds = divmod(remainder, 60)
        self.master_time_label.config(text=f"Master Time: {int(hours):02}:{int(minutes):02}:{int(seconds):02}")

    def start_task(self):
        if self.task_running:
            messagebox.showwarning("Warning", "A task is already running.")
            return

        task_name = self.task_name_entry.get().strip()
        try:
            minutes = int(self.time_entry.get().strip())
        except ValueError:
            messagebox.showerror("Invalid Input", "Please enter a valid number of minutes.")
            return

        self.task_seconds = minutes * 60
        if self.use_master_time.get():
            if self.task_seconds > self.master_time_remaining:
                messagebox.showerror("Not Enough Time", "Not enough time in Master Time Bank.")
                return

        self.task_name = task_name
        self.task_running = True
        self.task_paused = False
        self.pause_button.config(state=tk.NORMAL)
        self.task_thread = threading.Thread(target=self.run_timer)
        self.task_thread.start()

    def run_timer(self):
        start_time = time.time()
        while self.task_seconds > 0 and self.task_running:
            if not self.task_paused:
                elapsed = time.time() - start_time
                self.task_seconds -= 1
                self.update_timer_label()
                time.sleep(1)
        if self.task_seconds <= 0:
            self.complete_task()

    def update_timer_label(self):
        hours, remainder = divmod(self.task_seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        self.timer_label.config(text=f"{int(hours):02}:{int(minutes):02}:{int(seconds):02}")

    def pause_task(self):
        if self.task_running:
            self.task_paused = True
            self.pause_button.config(state=tk.DISABLED)
            self.resume_button.config(state=tk.NORMAL)

    def resume_task(self):
        if self.task_running:
            self.task_paused = False
            self.pause_button.config(state=tk.NORMAL)
            self.resume_button.config(state=tk.DISABLED)

    def complete_task(self):
        self.task_running = False
        self.pause_button.config(state=tk.DISABLED)
        self.resume_button.config(state=tk.DISABLED)
        self.timer_label.config(text="00:00:00")
        self.log_task()
        if self.use_master_time.get():
            self.master_time_remaining -= int(self.time_entry.get()) * 60
            self.update_master_time_label()
        messagebox.showinfo("Task Complete", f"'{self.task_name}' is complete!")

    def log_task(self):
        with open("task_log.csv", mode="a", newline="") as file:
            writer = csv.writer(file)
            writer.writerow([self.task_name, self.time_entry.get().strip(), datetime.now().strftime("%Y-%m-%d %H:%M:%S")])

    def reset_master_time(self):
        pwd = simpledialog.askstring("Reset Master Time", "Enter parent password:", show='*')
        if pwd == MASTER_PASSWORD:
            self.master_time_remaining = MASTER_TIME_TOTAL
            self.update_master_time_label()
            messagebox.showinfo("Success", "Master time has been reset.")
        else:
            messagebox.showerror("Incorrect Password", "That password is incorrect.")

if __name__ == "__main__":
    root = tk.Tk()
    app = TaskTimerApp(root)
    root.mainloop()
