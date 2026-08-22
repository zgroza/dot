#!/usr/bin/env bash

# Function to create a symlink, handling existing files/dirs
create_link() {
    source_path=$1
    target_path=$2

    # Targets come in already expanded; no eval needed.
    target_path_expanded=$target_path

    # Check if the source path exists
    if [ ! -e "$source_path" ]; then
        echo "Source path does not exist: $source_path"
        return
    fi

    # Handle existing target
    if [ -e "$target_path_expanded" ] || [ -L "$target_path_expanded" ]; then
        item_type="item"
        if [ -L "$target_path_expanded" ]; then
            item_type="link"
        elif [ -d "$target_path_expanded" ]; then
            item_type="directory"
        elif [ -f "$target_path_expanded" ]; then
            item_type="file"
        fi

        echo "A $item_type already exists at $target_path."
        read -p "Do you want to remove it and create a new link? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping..."
            return
        fi
        rm -rf "$target_path_expanded"
    fi

    # Create parent directory if it does not exist
    mkdir -p "$(dirname "$target_path_expanded")"

    ln -s "$source_path" "$target_path_expanded"
    echo "Created link: $target_path -> $source_path"
}

usage() {
    echo "Usage: $0 [linux|mac]"
    echo
    echo "Links the shared configs plus the ones for the given OS."
    echo "Without an argument the OS is detected with uname."
    exit 2
}

# Get the directory of the script itself. Avoid readlink -f, BSD doesn't have it.
script_dir=$(cd "$(dirname "$0")" && pwd -P)

case "${1:-}" in
    linux|mac)
        os=$1
        ;;
    "")
        case "$(uname -s)" in
            Linux)  os=linux ;;
            Darwin) os=mac ;;
            *)      echo "Unsupported system: $(uname -s)"; usage ;;
        esac
        echo "Detected $os."
        ;;
    *)
        usage
        ;;
esac

# Shared between systems. zsh/ is linked whole; .zshrc picks the os/ subdir
# to load at runtime, so the same tree works everywhere.
common_links=(
    "zsh/.zshrc:$HOME/.zshrc"
    "zsh:$HOME/.config/zsh"
    "nvim:$HOME/.config/nvim"
    "kitty:$HOME/.config/kitty"
    "tmux/.tmux.conf:$HOME/.tmux.conf"
)

linux_links=(
    "rofi:$HOME/.config/rofi"
    "gtklock:$HOME/.config/gtklock"
    "sway:$HOME/.config/sway"
    "swayidle:$HOME/.config/swayidle"
    "swaylock:$HOME/.config/swaylock"
    "swaync:$HOME/.config/swaync"
    "swayidle:$HOME/.swayidle"
    "hypr:$HOME/.config/hypr"
    "waybar:$HOME/.config/waybar"
)

mac_links=(
    "macos/Services/FnKeys.workflow:$HOME/Library/Services/FnKeys.workflow"
)

link_all() {
    local entry
    for entry in "$@"; do
        create_link "$script_dir/${entry%%:*}" "${entry#*:}"
    done
}

link_all "${common_links[@]}"

case $os in
    linux) link_all "${linux_links[@]}" ;;
    mac)   link_all "${mac_links[@]}" ;;
esac
