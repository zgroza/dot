typeset -U path
path=(
  $HOME/bin
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/.npm-packages/bin
  $path
)

export EDITOR=nvim
export MANPAGER='nvim +Man!'

# Command used to hand a file to the desktop; set per OS.
export OPENER=${OPENER:-xdg-open}
