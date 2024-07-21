import tkinter as tk
from phue import Bridge

# Replace with your bridge's IP address
BRIDGE_IP = 'IP_Of_Bridge_Here'

# Connect to the bridge
b = Bridge(BRIDGE_IP)
b.connect()

# Function to toggle the light
def toggle_light():
    current_state = b.get_light(2, 'on')
    b.set_light(2, 'on', not current_state)

# Create the main window
root = tk.Tk()
root.title("Philips Hue Light Control")

# Create a button to toggle the light
toggle_button = tk.Button(root, text="Toggle Light", command=toggle_light)
toggle_button.pack(pady=20)

# Run the application
root.mainloop()
