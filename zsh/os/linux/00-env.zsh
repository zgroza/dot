export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/ssh-agent.socket}"

export OPENER=xdg-open

# GNU coreutils base64.
_b64encode() { base64 -w 0 }
_b64decode() { base64 -d -i 2>/dev/null }
