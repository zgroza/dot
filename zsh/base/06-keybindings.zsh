# Keybindings
set -o vi
unsetopt BEEP
bindkey -v '^?' backward-delete-char


# Function to add "sudo " to the beginning of the command line
zle -N _add_sudo_to_command

# Bind Ctrl+A to add "sudo "
bindkey '^A' _add_sudo_to_command

# Get command for clearing scrollback
zle -N _reset

# Bind Ctrl+P to reset scrollback
bindkey '^P' _reset

# Create the ZLE widget from the function.
zle -N _fzf_nvim_select

# Bind the widget to both vi insert and vi command modes.
bindkey -M viins '^E' _fzf_nvim_select
bindkey -M vicmd '^E' _fzf_nvim_select

zle -N _cd_chromium
bindkey '^[d' _cd_chromium

zle -N _pwd_to_clipboard
bindkey '^[s' _pwd_to_clipboard
bindkey -M vicmd '^[s' _pwd_to_clipboard

