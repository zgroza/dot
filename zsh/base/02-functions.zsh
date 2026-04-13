amend() {
  git commit -a --amend --no-edit
}

record_screen_to_file() {
  wf-recorder -g "$(slurp)" -f "$@"
}

md() {
  pandoc -f markdown -t html5 "$1" -o "/tmp/$1.html"
  xdg-open "/tmp/$1.html"
}

get_clipboard() {
  case "$1" in (c|p) ;; (*) echo "Usage: get_clipboard p|c"; return ;; esac
  local temp=`mktemp`
  printf '\e]52;'$1';?\e\' >$TTY
  read -d '\\n' -e -r -t 2 <$TTY >$temp
  if (( $? )); then print "no clipboard available"; return; fi 
  clipboard_contents=`tr -d '\033' <$temp | sed 's/^.*;//' | base64 -d -i`
  rm $temp
  echo -n "$clipboard_contents"
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
  # base64 with -w 0 to disable line wrapping.
  printf "\e]52;c;%s\e\\" "$(echo -n "$input" | base64 -w 0)" >$TTY
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

run_in_nice_augroup () {
  command="echo 15 | tee /proc/self/autogroup; $@"
  setsid -w zsh -c "$command"  
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

