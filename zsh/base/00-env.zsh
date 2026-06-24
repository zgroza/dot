export PATH=$HOME/bin:\
$HOME/.local/bin:\
$HOME/bin:\
$HOME/.cargo/bin:\
$HOME/.npm-packages/bin:\
$PATH

export EDITOR=nvim
export MANPAGER='nvim +Man!'

export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/ssh-agent.socket}"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
