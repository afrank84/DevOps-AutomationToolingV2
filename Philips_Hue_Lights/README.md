# Philips Hue light examples

Both examples use Python's `phue` package and network access to a Hue bridge.
Set the bridge IP in a local copy and authorize bridge registration as required
by phue (typically pressing the bridge link button during initial connection).
They address **light ID 2**, not every light. Inspect your bridge's IDs first.
Neither was run against physical lights for this documentation.

## [ConnectToBridgeAndTest.py](ConnectToBridgeAndTest.py)

Creates a Bridge connection, calls `connect()` and `get_api()`, then sets light
2's `on` state to `False`. Invoke with Python after replacing the bridge placeholder.
It turns a real light off immediately without a prompt and does not print or
save the returned API inventory. It has no error handling or automatic restore.

## [ConnectToBridgeAndTest_GUI.py](ConnectToBridgeAndTest_GUI.py)

Connects to configured `BRIDGE_IP`, opens a Tkinter window, and provides a Toggle
Light button that reads light 2's current on/off state and writes its inverse.
Run with Python, phue, Tkinter, and a graphical desktop. Connection/registration
happens before the window is created. Button requests run synchronously, errors
are not caught, and state changes persist on the bridge after closing the GUI.

Older [Python notes](PythonReadMe.md) and [JavaScript notes](JsReadme.md) remain
available; they are separate examples, not extra configuration read by these scripts.
