#!/bin/bash

# Function to create a symlink, handling existing files/dirs
create_link() {
    source_path=$1
    target_path=$2

    # Expand tilde to home directory
    eval target_path_expanded=$target_path

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

# Get the directory of the script itself
script_dir=$(dirname "$(readlink -f "$0")")

create_link "$script_dir/zsh/.zshrc" ~/.zshrc
create_link "$script_dir/zsh/base" ~/.config/zsh/base
create_link "$script_dir/nvim" ~/.config/nvim
create_link "$script_dir/rofi" ~/.config/rofi
create_link "$script_dir/gtklock" ~/.config/gtklock
create_link "$script_dir/sway" ~/.config/sway
create_link "$script_dir/swayidle" ~/.config/swayidle
create_link "$script_dir/swaylock" ~/.config/swaylock
create_link "$script_dir/swaync" ~/.config/swaync
create_link "$script_dir/swayidle" ~/.swayidle
create_link "$script_dir/hypr" ~/.config/hypr
create_link "$script_dir/kitty" ~/.config/kitty
create_link "$script_dir/waybar" ~/.config/waybar
create_link "$script_dir/tmux/.tmux.conf" ~/.tmux.conf