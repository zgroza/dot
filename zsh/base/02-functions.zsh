amend() {
  git commit -a --amend --no-edit
}

md() {
  pandoc -f markdown -t html5 "$1" -o "/tmp/$1.html"
  "$OPENER" "/tmp/$1.html"
}

get_clipboard() {
  case "${1:-c}" in (c|p) ;; (*) echo "Usage: get_clipboard [p|c]" >&2; return 1 ;; esac
  if [[ -z "$TTY" || ! -r "$TTY" || ! -w "$TTY" ]]; then
    print "no clipboard available" >&2
    return 1
  fi

  local clip="" chunk="" bel=$'\a' saved_stty
  saved_stty=$(stty -g <$TTY 2>/dev/null)
  {
    # Query terminal for clipboard via OSC 52.
    # Raw mode is required because the terminal response lacks newlines.
    stty raw -echo
    printf '\e]52;%s;?\a' "${1:-c}" >$TTY
    zmodload -F zsh/system b:sysread 2>/dev/null
    # Read response (completes in one shot for payloads <8KB, loops if fragmented/large).
    while sysread -t 2 -s 8192 chunk; do
      clip+="$chunk"
      [[ "$clip" == *"$bel"* || "$clip" == *'\'* ]] && break
    done
  } always {
    # Guarantee terminal state is restored on error or interrupt.
    [[ -n "$saved_stty" ]] && stty "$saved_stty" 2>/dev/null
  } <$TTY

  if [[ -z "$clip" ]]; then
    print "no clipboard available" >&2
    return 1
  fi

  # Accept both BEL (\a) and ESC \ (ST) terminators returned by different terminals.
  clip="${clip%%$bel*}"
  clip="${clip%%\\*}"

  local b64_payload
  b64_payload=$(printf '%s' "$clip" | tr -d '\033' | sed 's/^.*;//')
  # '?' indicates the terminal denied permission to read the clipboard.
  if [[ -z "$b64_payload" || "$b64_payload" == "?" ]]; then
    print "no clipboard available" >&2
    return 1
  fi

  printf '%s' "$b64_payload" | _b64decode
}

set_clipboard() {
  # Read from stdin, and send to clipboard via OSC 52
  local input
  # Trailing sentinel preserves newlines that $() substitution would strip.
  input=$(cat; printf x)
  input="${input%x}"

  # Terminals have limits on escape sequence length.
  # Let's pick a conservative 750KB limit on the input.
  if (( ${#input} > 768000 )); then
    print "Input too large for clipboard." >&2
    return 1
  fi

  if [[ -z "$TTY" || ! -w "$TTY" ]]; then
    print "no terminal available" >&2
    return 1
  fi

  printf '\e]52;%s;%s\a' "${1:-c}" "$(printf '%s' "$input" | _b64encode)" >$TTY
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

