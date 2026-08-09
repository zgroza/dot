# zsh layout

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
A file like `os/mac/01-aliases.zsh` extends or overrides `base/01-aliases.zsh`.

Portability seams that keep things out of `os/`:

- `$OPENER` — `xdg-open` or `open`
- `_b64encode` / `_b64decode` — GNU vs BSD `base64` flags
- `zsh_source_first a b c` — sources the first candidate that exists, used for
  plugin and prompt paths

`~/.zsh_proprietary` is sourced last if present, and is not in this repo.

## GNU coreutils on the Mac

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
