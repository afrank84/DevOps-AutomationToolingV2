Write-Host "Press any key to see its code, or press 'Escape' to exit."

# Loop to capture keystrokes
do {
    $key = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    Write-Host "Key pressed: $($key.Character) - Key code: $($key.VirtualKeyCode)"
} while ($key.VirtualKeyCode -ne 27) # 27 is the Escape key code
