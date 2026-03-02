Require nvim
Require vhs

Output demo/snacks-tea-demo.gif

Set Shell "bash"
Set FontSize 16
Set FontFamily "CaskaydiaCove Nerd Font Mono"
Set Padding 12
Set Width 1500
Set Height 860
Set Theme "Catppuccin Mocha"
Set TypingSpeed 70ms

Hide
Type "nvim -u demo/demo.lua"
Enter
Show

# Wait for lazy + picker to load
Sleep 3200ms

# Filter list
Type "readability"
Sleep 1300ms

# Open actions menu from selected PR
Enter
Sleep 1500ms

# Pick open-in-buffer action by filtering
Type "open in buffer"
Sleep 900ms
Enter
Sleep 3000ms

# Toggle comments and diff sections
Escape
Type ":TeaToggleComments"
Enter
Sleep 1500ms
Escape
Type ":TeaToggleDiff"
Enter
Sleep 1500ms

# Refresh buffer
Escape
Type ":TeaRefresh"
Enter
Sleep 2200ms

# Open picker again and add a comment action
Escape
Type ":TeaDemo"
Enter
Sleep 2200ms
Type "parser"
Sleep 900ms
Enter
Sleep 1200ms
Type "comment"
Sleep 700ms
Enter
Sleep 1400ms
Type "Nice parser fixes. Demo comment from VHS."
Sleep 700ms
Ctrl+S
Sleep 2200ms

# Exit Neovim
Escape
Type ":qa!"
Enter
Sleep 500ms
