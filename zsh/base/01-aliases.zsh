# Generic Aliases
alias l='reset'
alias la='ls -laht --color --hyperlink=auto'
alias ls='ls -a --color --hyperlink=auto'
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias limit_cores="taskset -c 4-$((`nproc` - 1))"
if [[ "$TERM" == "xterm-kitty" ]]; then
  alias s="kitten ssh"
else
  alias s="ssh"
fi
alias e="$EDITOR"
alias session="tmux -u new -A -s session"
