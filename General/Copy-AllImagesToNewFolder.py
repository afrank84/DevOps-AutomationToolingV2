#!/usr/bin/env python3

import shutil
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox

IMAGE_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".gif",
    ".bmp", ".tif", ".tiff", ".webp",
    ".svg", ".heic", ".heif", ".avif",
    ".ico"
}


def select_source():
    folder = filedialog.askdirectory(title="Select Source Folder")
    if folder:
        source_var.set(folder)


def select_destination():
    folder = filedialog.askdirectory(title="Select Destination Folder")
    if folder:
        dest_var.set(folder)


def copy_images():
    source = Path(source_var.get())
    dest = Path(dest_var.get())

    if not source.exists():
        messagebox.showerror("Error", "Please select a valid source folder.")
        return

    if not dest.exists():
        dest.mkdir(parents=True, exist_ok=True)

    copied = 0
    skipped = 0

    for file in source.rglob("*"):
        if file.is_file() and file.suffix.lower() in IMAGE_EXTENSIONS:
            destination = dest / file.name

            # Prevent overwriting duplicate filenames
            if destination.exists():
                stem = file.stem
                suffix = file.suffix
                counter = 1
                while destination.exists():
                    destination = dest / f"{stem}_{counter}{suffix}"
                    counter += 1

            shutil.copy2(file, destination)
            copied += 1

    messagebox.showinfo(
        "Finished",
        f"Copied {copied} images.\nSkipped {skipped} files."
    )


root = tk.Tk()
root.title("Recursive Image Copier")
root.resizable(False, False)

source_var = tk.StringVar()
dest_var = tk.StringVar()

# Source
tk.Label(root, text="Source Folder").grid(row=0, column=0, padx=10, pady=(10, 5), sticky="w")
tk.Entry(root, textvariable=source_var, width=60).grid(row=1, column=0, padx=10)
tk.Button(root, text="Browse...", command=select_source).grid(row=1, column=1, padx=10)

# Destination
tk.Label(root, text="Destination Folder").grid(row=2, column=0, padx=10, pady=(10, 5), sticky="w")
tk.Entry(root, textvariable=dest_var, width=60).grid(row=3, column=0, padx=10)
tk.Button(root, text="Browse...", command=select_destination).grid(row=3, column=1, padx=10)

# Copy button
tk.Button(
    root,
    text="Copy Images",
    command=copy_images,
    width=20,
    height=2
).grid(row=4, column=0, columnspan=2, pady=20)

root.mainloop()
