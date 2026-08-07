if (( ${ZSH_HAS_GNU_COREUTILS:-0} )); then
  # GNU ls, so --color and --hyperlink work exactly like on Linux. The
  # hyperlinks are what make kitty's open-actions fire on clicked filenames.
  alias ls='gls -a --color --hyperlink=auto'
  alias la='gls -laht --color --hyperlink=auto'
else
  # BSD ls: -G for colour, and no hyperlink support at all.
  alias ls='ls -aG'
  alias la='command ls -lahtG'
fi
