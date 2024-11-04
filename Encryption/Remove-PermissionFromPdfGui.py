import tkinter as tk
from tkinter import filedialog, messagebox
import pikepdf
import os

# Function to unlock the PDF
def unlock_pdf():
    # Ask the user to select a PDF file
    file_path = filedialog.askopenfilename(filetypes=[("PDF Files", "*.pdf")])
    if not file_path:
        return  # If no file selected, do nothing

    # Set the save path for the unlocked PDF
    save_path = os.path.join(os.path.dirname(file_path), "unlocked_" + os.path.basename(file_path))

    try:
        # Open and save the unlocked PDF
        with pikepdf.open(file_path) as pdf:
            pdf.save(save_path)
        messagebox.showinfo("Success", f"Unlocked PDF saved as:\n{save_path}")
    except Exception as e:
        messagebox.showerror("Error", f"Failed to unlock PDF:\n{e}")

# Set up the GUI
root = tk.Tk()
root.title("PDF Unlocker")
root.geometry("300x150")

label = tk.Label(root, text="Unlock a PDF file:")
label.pack(pady=10)

unlock_button = tk.Button(root, text="Select and Unlock PDF", command=unlock_pdf)
unlock_button.pack(pady=10)

root.mainloop()
