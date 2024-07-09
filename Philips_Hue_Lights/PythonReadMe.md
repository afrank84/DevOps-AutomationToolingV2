# Philips Hue Light Control Script
This Python script provides a simple interface for controlling Philips Hue lights through the Philips Hue Bridge. It demonstrates connecting to the Hue Bridge, retrieving the current API state, and setting the on/off state of a specified light.

# Prerequisites
Before running this script, ensure you have the following:

A Philips Hue Bridge connected to your network.
At least one Philips Hue light set up and connected to your Hue Bridge.
The IP address of your Philips Hue Bridge.
Python 3 installed on your system.
The phue Python library installed. You can install it using pip:
```bash
pip install phue
```

# Configuration
Find the IP Address of Your Hue Bridge: If you do not know the IP address of your Hue Bridge, you can find it by checking your router's connected devices list or using a network scanning tool.

Connect to the Hue Bridge: The first time you run the script, press the button on the Hue Bridge before or shortly after executing the script to authenticate the connection.

# Usage
The script is ready to run as is, but you may wish to modify it to suit your needs. To run the script, simply navigate to the script's directory in your terminal and execute:

bash
Copy code
python hue_control.py

# Script Functions
Connect to the Bridge: Establishes a connection to the Philips Hue Bridge.
Get API State: Retrieves the current state of the Hue system, including lights, groups, configurations, etc.
Set Light State: Changes the on/off state of a specified light. The script turns off the light with an ID of 2 as an example.
Customization
To control different aspects of your lights (e.g., brightness, color), modify the b.set_light call with additional parameters as per the phue library's documentation.

#Troubleshooting
If the script cannot connect to the Hue Bridge, ensure your device and the Hue Bridge are on the same network and the IP address is correct.
If commands are not affecting your lights, ensure the light ID used in the script matches the actual ID of your Hue light. Light IDs can be found by inspecting the data returned by b.get_api().
