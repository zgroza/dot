# SSH_AUTH_SOCK is set by launchd, don't touch it.
# Homebrew is set up in init.zsh, it has to run before base/.

# GNU coreutils are optional here (brew install coreutils). When they are
# around, the few things that want GNU flags reach for the g-prefixed tools
# instead. Nothing is shadowed on PATH, so the system tools stay as they are.
(( $+commands[gls] )) && ZSH_HAS_GNU_COREUTILS=1

# Same with findutils
(( $+commands[gfind] )) && ZSH_HAS_GNU_FINDUTILS=1

# Security-key support via the keychain (was in ~/.zprofile).
export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib

export OPENER=open

# BSD base64 has no -w, so strip the wrapping by hand. Decode is -d on both
# BSD and GNU; BSD's -D also works but GNU has no such flag, so avoid it in
# case coreutils ever ends up first on PATH.
_b64encode() { base64 | tr -d '\n' }
_b64decode() { base64 -d 2>/dev/null }
