# Set ZDOTDIR to the home directory if not already set.
ZDOTDIR=${ZDOTDIR:-$HOME}

# Define the configuration directory.
ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Which os/ subdirectory to load on top of base/.
case "$(uname -s)" in
  Darwin) ZSH_OS=mac ;;
  Linux)  ZSH_OS=linux ;;
  *)      ZSH_OS=unknown ;;
esac

# Helpers used by the config files.
[[ -r "$ZSH_CONFIG_DIR/lib.zsh" ]] && source "$ZSH_CONFIG_DIR/lib.zsh"

# Anything base/ needs on PATH before it probes for tools (Homebrew, etc.).
[[ -r "$ZSH_CONFIG_DIR/os/$ZSH_OS/init.zsh" ]] && source "$ZSH_CONFIG_DIR/os/$ZSH_OS/init.zsh"

# Load the portable configuration, then the OS-specific additions on top.
# Matching numeric prefixes mean os/$ZSH_OS/01-aliases.zsh extends
# base/01-aliases.zsh, and so on. Only numbered files are picked up, so
# init.zsh above is not sourced twice.
for config_file (
  $ZSH_CONFIG_DIR/base/[0-9]*.zsh(N)
  $ZSH_CONFIG_DIR/os/$ZSH_OS/[0-9]*.zsh(N)
); do
  source $config_file
done

# Source proprietary extensions if they exist.
if [[ -f ~/.zsh_proprietary ]]; then
  source ~/.zsh_proprietary
fi
