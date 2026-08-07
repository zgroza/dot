# My dotfiles

Those are just my dotfiles. Mostly Linux, with the shell config shared with a
Mac. Feel free to use if you see anything interesting. Have an awesome day!

## Using this

There is a helper script for creating appropriate links. It is non-destructive
by default and will ask before deleting any current files/directories:

```zsh
./create_links.sh          # detects the OS with uname
./create_links.sh mac      # or linux, to override
```

Shared configs (`zsh`, `nvim`, `kitty`, `tmux`) are always linked. The OS
decides whether the Wayland/sway/hypr side gets linked on top.

## zsh layout

`zsh/` is linked whole to `~/.config/zsh`, and `.zshrc` decides at runtime
which OS files to load, so the same checkout works on both systems:

```
zsh/
  .zshrc          # loader
  lib.zsh         # helpers (zsh_source_first)
  base/           # portable config, numbered by topic
  os/linux/       # extends the matching base/ file
  os/mac/         # init.zsh runs before base/, for Homebrew's PATH
```

Load order is all of `base/`, then all of `os/<os>/`. Only numbered files are
sourced by the loop, so `os/*/init.zsh` and `lib.zsh` are not picked up twice.
A file like `os/mac/01-aliases.zsh` extends or overrides
`base/01-aliases.zsh`.

Portability seams that keep things out of `os/`:

- `$OPENER` — `xdg-open` or `open`
- `_b64encode` / `_b64decode` — GNU vs BSD `base64` flags
- `zsh_source_first a b c` — sources the first candidate that exists, used for
  plugin and prompt paths

`~/.zsh_proprietary` is sourced last if present, and is not in this repo.

### GNU coreutils on the Mac

Optional. `os/mac/00-env.zsh` sets `ZSH_HAS_GNU_COREUTILS` when `gls` is on
PATH, and the `ls`/`la` aliases use `gls` with the same
`--color --hyperlink=auto` as Linux when it is, or BSD `-G` when it is not. The
hyperlinks are what make kitty's open-actions fire on clicked filenames, so
without coreutils that feature is simply absent on the Mac.

```zsh
brew install coreutils
```

The g-prefixed tools are used explicitly rather than putting
`.../libexec/gnubin` on PATH, so the system tools stay untouched. Note that
`base64 -D` decodes on BSD but not GNU, while `-d` works on both — worth
remembering if gnubin ever does end up on PATH.

## kitty layout

kitty splits itself, no help from the link script needed. `kitty.conf` ends with

```conf
globinclude os/${KITTY_OS}.conf
```

and kitty sets `KITTY_OS` to `linux`, `macos` or `bsd` while processing
includes. `globinclude` rather than `include`, because a glob matching nothing
is quiet whereas a missing `include` logs a warning.

`open-actions.conf` ignores `include` and `globinclude` entirely, so the
`xdg-open` vs `open` difference goes through an `action_alias` that dispatches
on whichever opener the system has.

TODO: Maybe use some dotfile manager for symlinking instead of a custom script.
