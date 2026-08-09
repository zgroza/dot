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

On a Mac there is one further step, kept out of the link script because it
writes system state rather than creating symlinks:

```zsh
./macos/apply-defaults.sh   # restores shortcuts, trackpad and Dock settings
```

## Where things are

Anything with a layout worth explaining documents itself next to the config:

- [zsh/](zsh/README.md) — the `base/` + `os/<os>/` loader, portability seams,
  and the optional GNU coreutils setup on the Mac
- [kitty/](kitty/README.md) — how `KITTY_OS` splits the config without help
  from the link script
- [macos/](macos/README.md) — capturing keyboard shortcuts, trackpad and Dock
  settings into checked-in plists

The rest is unremarkable: `nvim`, `tmux`, and the Wayland side (`sway`, `hypr`,
`waybar`, `rofi`, `swaync`, `swaylock`, `gtklock`, `swayidle`).

TODO: Maybe use some dotfile manager for symlinking instead of a custom script.
