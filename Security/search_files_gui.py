import tkinter as tk
from tkinter import filedialog, messagebox
from pathlib import Path

def search_files():
    """Perform the search for files in the selected results.txt."""
    if not list_file_path.get() or not results_file_path.get():
        messagebox.showerror("Error", "Both the list file and results file must be selected.")
        return

    list_path = Path(list_file_path.get())
    results_path = Path(results_file_path.get())

    if not list_path.exists() or not results_path.exists():
        messagebox.showerror("Error", "One or both selected files do not exist.")
        return

    try:
        with open(list_path, "r") as f:
            file_list = [line.strip() for line in f if line.strip()]

        with open(results_path, "r") as f:
            results_content = f.read()

        output_file = "search_results.txt"
        with open(output_file, "w") as out:
            for filename in file_list:
                if filename in results_content:
                    out.write(f"{filename}: Found in {results_path}\n")
                else:
                    out.write(f"{filename}: Not Found in {results_path}\n")

        messagebox.showinfo("Success", f"Search completed. Results saved in {output_file}.")
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

tk.Button(root, text="Search", command=search_files).grid(row=2, column=0, columnspan=3, pady=10)

# Run the application
root.mainloop()
