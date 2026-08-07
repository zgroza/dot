# Helpers available to every config file below.

# Source the first readable file from the given candidates. Lets base/ configs
# refer to things that live in different places on different systems.
zsh_source_first() {
  local candidate
  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 1
}
