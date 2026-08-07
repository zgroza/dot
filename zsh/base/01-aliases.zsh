# Generic Aliases
# `ls`/`la` differ between GNU and BSD coreutils and live in os/.
alias l='reset'
if [[ "$TERM" == "xterm-kitty" ]]; then
  alias s="kitten ssh"
else
  alias s="ssh"
fi
alias e="$EDITOR"
alias session="tmux -u new -A -s session"
