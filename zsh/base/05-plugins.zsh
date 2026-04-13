# Plugins
# fzf
if command -v fzf &>/dev/null; then
  FZF_VERSION="$(fzf --version | cut -d' ' -f1)"
  [[ "$(printf '%s\n' 0.48 "$FZF_VERSION" | sort -V | head -n1)" = 0.48 ]] \
    &&  fzf --zsh | source /dev/stdin
  # decorates fzf search window with a border, and make the search box 20% high
  export FZF_DEFAULT_OPTS='--height 20% --border'
fi

# autosuggestions - possible locations
for file in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -f "$file" ]] && source "$file"
done
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# syntax highlighting
for file in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -f "$file" ]] && source "$file"
done

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
