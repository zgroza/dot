# Plugins
# The autosuggestions/syntax-highlighting install paths differ per system and
# live in os/*/05-plugins.zsh.

# fzf
if command -v fzf &>/dev/null; then
  FZF_VERSION="$(fzf --version | cut -d' ' -f1)"
  [[ "$(printf '%s\n' 0.48 "$FZF_VERSION" | sort -V | head -n1)" = 0.48 ]] \
    &&  fzf --zsh | source /dev/stdin
  # decorates fzf search window with a border, and make the search box 20% high
  export FZF_DEFAULT_OPTS='--height 20% --border'
fi

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
