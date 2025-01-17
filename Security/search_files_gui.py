import tkinter as tk
from tkinter import filedialog, messagebox
from pathlib import Path
import chardet  # Requires installation: pip install chardet


def detect_file_encoding(file_path):
    """Detect the encoding of a file."""
    with open(file_path, "rb") as f:
        raw_data = f.read()
    result = chardet.detect(raw_data)
    encoding = result["encoding"]
    if encoding:
        print(f"Detected encoding for {file_path}: {encoding}")
    else:
        print(f"Encoding not detected for {file_path}, falling back to utf-8.")
    return encoding or "utf-8"


def search_files():
    """Search for files and/or keyword in the results file and display counts."""
    if not results_file_path.get():
        messagebox.showerror("Error", "The results file must be selected.")
        return

    keyword = keyword_entry.get().strip()
    results_path = Path(results_file_path.get())

    if not results_path.exists():
        messagebox.showerror("Error", "The selected results file does not exist.")
        return

    try:
        results_encoding = detect_file_encoding(results_path)

        with open(results_path, "r", encoding=results_encoding) as f:
            results_content = f.readlines()  # Read file line by line for keyword search

        match_count = 0
        output_file = "search_results.txt"
        with open(output_file, "w", encoding="utf-8") as out:
            if list_file_path.get():
                list_path = Path(list_file_path.get())
                if not list_path.exists():
                    messagebox.showerror("Error", "The selected list file does not exist.")
                    return

                list_encoding = detect_file_encoding(list_path)
                with open(list_path, "r", encoding=list_encoding) as f:
                    file_list = [line.strip() for line in f if line.strip()]

                for filename in file_list:
                    if filename in "".join(results_content):
                        out.write(f"Found in {results_path}: {filename}\n")
                        match_count += 1
                    else:
                        out.write(f"No Results for {results_path}: {filename}\n")

            if keyword:
                out.write(f"\nSearching for keyword: '{keyword}'\n")
                for line in results_content:
                    if keyword in line:
                        out.write(f"Line found: {line.strip()}\n")
                        match_count += 1

        messagebox.showinfo(
            "Success", 
            f"Search completed. {match_count} matches found. Results saved in {output_file}."
        )
    except Exception as e:
        messagebox.showerror("Error", f"An error occurred: {e}")




def select_list_file():
    """Open a file dialog to select the list file."""
    file_path = filedialog.askopenfilename(title="Select List File", filetypes=[("Text Files", "*.txt")])
    list_file_path.set(file_path)


def select_results_file():
    """Open a file dialog to select the results.txt file."""
    file_path = filedialog.askopenfilename(title="Select Results File", filetypes=[("Text Files", "*.txt")])
    results_file_path.set(file_path)


# Create the main application window
root = tk.Tk()
root.title("File Search Tool")
root.minsize(600, 600)  # Set minimum size of the application window

# Variables to hold file paths
list_file_path = tk.StringVar()
results_file_path = tk.StringVar()

# Create GUI components
tk.Label(root, text="Select List File:").grid(row=0, column=0, padx=10, pady=5, sticky="w")
tk.Entry(root, textvariable=list_file_path, width=50).grid(row=0, column=1, padx=10, pady=5)
tk.Button(root, text="Browse", command=select_list_file).grid(row=0, column=2, padx=10, pady=5)

tk.Label(root, text="Select Results File:").grid(row=1, column=0, padx=10, pady=5, sticky="w")
tk.Entry(root, textvariable=results_file_path, width=50).grid(row=1, column=1, padx=10, pady=5)
tk.Button(root, text="Browse", command=select_results_file).grid(row=1, column=2, padx=10, pady=5)

tk.Label(root, text="Enter Keyword:").grid(row=2, column=0, padx=10, pady=5, sticky="w")
keyword_entry = tk.Entry(root, width=50)
keyword_entry.grid(row=2, column=1, padx=10, pady=5)

tk.Button(root, text="Search", command=search_files).grid(row=3, column=0, columnspan=3, pady=10)

# Run the application
root.mainloop()
