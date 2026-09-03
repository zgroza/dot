amend() {
  git commit -a --amend --no-edit
}

md() {
  pandoc -f markdown -t html5 "$1" -o "/tmp/$1.html"
  "$OPENER" "/tmp/$1.html"
}

get_clipboard() {
  case "$1" in (c|p) ;; (*) echo "Usage: get_clipboard p|c"; return ;; esac
  printf '\e]52;'$1';?\e\' >$TTY
  local clip
  read -s -r -d '\' -t 2 clip <$TTY
  if (( $? )); then print "no clipboard available"; return; fi
  local clipboard_contents
  clipboard_contents=$(printf '%s' "$clip" | tr -d '\033' | sed 's/^.*;//' | _b64decode)
  printf '%s' "$clipboard_contents"
}

set_clipboard() {
  # Read from stdin, and send to clipboard via OSC 52
  local input
  input=$(cat)
  # Terminals have limits on escape sequence length.
  # Let's pick a conservative 750KB limit on the input.
  if (( ${#input} > 768000 )); then
    print "Input too large for clipboard." >&2
    return 1
  fi
  printf "\e]52;c;%s\e\\" "$(echo -n "$input" | _b64encode)" >$TTY
}

_reset() {
  tput reset
  zle redisplay
}

_add_sudo_to_command() {
  if [[ -n "$LBUFFER" ]]; then
    LBUFFER="sudo $LBUFFER"
  else
    LBUFFER="sudo "
  fi
  zle end-of-line
  zle redisplay
}

er() {
  local nvim_server
  if [[ -n "$NVIM" ]]; then
    nvim_server="$NVIM"
  elif [[ -f "/tmp/nvim" ]]; then
    nvim_server=$(cat /tmp/nvim)
  else
    echo "NVIM not set and /tmp/nvim not found"
    return 1
  fi

  if ! [[ -e "$nvim_server" ]]; then
    echo "Nvim server socket not found at $nvim_server"
    return 1
  fi

  NVIM="$nvim_server" nvim --server "$nvim_server" --remote-tab "$@"
}

_fzf_nvim_select() {
  local selected_file
  selected_file=$(find ~/ -maxdepth 1 -type f -name "*.nvim" | fzf)

  if [[ -n $selected_file ]]; then
    command nvim -S "${selected_file}"
  fi

  zle redisplay
}

_cd_chromium() {
  BUFFER="cd ~/chromium/src"
  zle accept-line
}

_pwd_to_clipboard() {
  pwd | set_clipboard
}

