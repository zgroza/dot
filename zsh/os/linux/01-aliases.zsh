alias ls='ls -a --color --hyperlink=auto'
alias la='ls -laht --color --hyperlink=auto'
alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
alias limit_cores="taskset -c 4-$((`nproc` - 1))"
