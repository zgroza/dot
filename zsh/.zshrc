# Set ZDOTDIR to the home directory if not already set.
ZDOTDIR=${ZDOTDIR:-$HOME}

# Define the base configuration directory.
ZSH_BASE_CONFIG_DIR="$ZDOTDIR/.config/zsh/base"

# Load all .zsh files from the base config directory.
if [[ -d "$ZSH_BASE_CONFIG_DIR" ]]; then
  for config_file ($ZSH_BASE_CONFIG_DIR/*.zsh(N)); do
    source $config_file
  done
fi

# Source proprietary extensions if they exist.
if [[ -f ~/.zsh_proprietary ]]; then
  source ~/.zsh_proprietary
fi
