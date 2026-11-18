if [[ -z "$SSH_AUTH_SOCK" && -n "$XDG_RUNTIME_DIR" ]]; then
  () {
    local sock
    for sock in "$XDG_RUNTIME_DIR/openssh_agent" "$XDG_RUNTIME_DIR/ssh-agent.socket"; do
      if [[ -S "$sock" ]]; then
        export SSH_AUTH_SOCK="$sock"
        break
      fi
    done
  }
fi

export OPENER=xdg-open

# GNU coreutils base64.
_b64encode() { base64 -w 0 }
_b64decode() { base64 -d -i 2>/dev/null }
