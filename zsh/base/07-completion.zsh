# Completion
autoload -Uz compinit
compinit
compdef _ssh s
[[ "$TERM_PROGRAM" == "vscode" ]] && . `code --locate-shell-integration-path zsh`
[[ "$TERM" == "xterm-kitty" ]] && kitty + complete setup zsh | source /dev/stdin
[[ ! -f "$NVM_DIR/bash_completion" ]] || . "$NVM_DIR/bash_completion"
