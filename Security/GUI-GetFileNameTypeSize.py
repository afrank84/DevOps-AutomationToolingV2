import os
import csv
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from datetime import datetime
import threading

# Function to get available drives (Windows only)
def get_drives():
    drives = []
    for drive in range(65, 91):  # ASCII A-Z
        drive_letter = f"{chr(drive)}:\\"
        if os.path.exists(drive_letter):
            drives.append(drive_letter)
    return drives

# Function to log messages to the output box
def log_message(message):
    output_box.insert(tk.END, message + "\n")
    output_box.see(tk.END)

# Function to start file scanning in a separate thread
def start_scan():
    selected_drive = drive_var.get()
    if not selected_drive:
        messagebox.showerror("Error", "No drive selected!")
        return
    
    scan_button.config(state=tk.DISABLED)
    progress_bar.start(10)
    log_message(f"Starting scan on {selected_drive}...")

    threading.Thread(target=scan_files, args=(selected_drive,), daemon=True).start()

# Function to scan files and export results to CSV
def scan_files(scan_path):
    computer_name = os.environ.get("COMPUTERNAME", "UnknownPC")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(scan_path, f"file_log_{computer_name}_{timestamp}.csv")

    try:
        with open(log_file, mode="w", newline="", encoding="utf-8") as csv_file:
            writer = csv.writer(csv_file)
            writer.writerow(["Full Name", "Name", "Extension", "Size (MB)"])

            for root, _, files in os.walk(scan_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    try:
                        file_size_mb = round(os.path.getsize(file_path) / (1024 * 1024), 2)
                        file_name, file_extension = os.path.splitext(file)
                        writer.writerow([file_path, file_name, file_extension, file_size_mb])
                    except Exception as e:
                        log_message(f"Error processing {file_path}: {e}")

        log_message(f"File scan complete. Log saved to: {log_file}")
    except Exception as e:
        log_message(f"Error during scan: {e}")

    progress_bar.stop()
    scan_button.config(state=tk.NORMAL)

# Create GUI window
root = tk.Tk()
root.title("File Scanner")
root.geometry("500x400")
root.resizable(False, False)

# Dropdown for drive selection
ttk.Label(root, text="Select Drive:").grid(row=0, column=0, padx=10, pady=10, sticky="w")

drive_var = tk.StringVar()
drive_dropdown = ttk.Combobox(root, textvariable=drive_var, state="readonly", width=10)
drive_dropdown["values"] = get_drives()
if drive_dropdown["values"]:
    drive_dropdown.current(0)
drive_dropdown.grid(row=0, column=1, padx=10, pady=10, sticky="w")

# Start scan button
scan_button = ttk.Button(root, text="Start Scan", command=start_scan)
scan_button.grid(row=0, column=2, padx=10, pady=10)

# Output text box for verbose logs
output_box = tk.Text(root, height=15, width=60, wrap="word", state=tk.NORMAL)
output_box.grid(row=1, column=0, columnspan=3, padx=10, pady=10)
output_box.insert(tk.END, "Ready...\n")

# Progress bar
progress_bar = ttk.Progressbar(root, mode="indeterminate", length=400)
progress_bar.grid(row=2, column=0, columnspan=3, padx=10, pady=10)

# Run the GUI
root.mainloop()
