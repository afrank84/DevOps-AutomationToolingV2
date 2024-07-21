import tkinter as tk
from tkinter import messagebox
from yt_dlp import YoutubeDL

def download_audio():
    url = url_entry.get()
    if not url:
        messagebox.showwarning("Input Error", "Please enter a YouTube URL")
        return

    audio_downloader = YoutubeDL({
        'format': 'bestaudio/best',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }]
    })

    try:
        audio_downloader.extract_info(url)
        messagebox.showinfo("Success", "Audio downloaded successfully")
    except Exception as e:
        messagebox.showerror("Error", f"Couldn't download the audio: {str(e)}")

# Create the main window
root = tk.Tk()
root.title("YouTube Audio Downloader")

# Create and place the URL entry
tk.Label(root, text="Enter YouTube URL:").grid(row=0, column=0, padx=10, pady=10)
url_entry = tk.Entry(root, width=50)
url_entry.grid(row=0, column=1, padx=10, pady=10)

# Create and place the download button
download_button = tk.Button(root, text="Download", command=download_audio)
download_button.grid(row=1, column=0, columnspan=2, pady=20)

# Run the application
root.mainloop()
