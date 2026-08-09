#!/usr/bin/env bash
set -euo pipefail

# Replays the checked-in defaults onto this machine. See domains.sh for what is
# tracked and how each domain is written back.
#
# Only com.apple.symbolichotkeys is replaced wholesale, so a shortcut set here
# and never captured is lost. Everything else merges key by key and leaves
# untracked settings -- notably the apps in your Dock -- alone.

if [ "$(uname -s)" != "Darwin" ]; then
    echo "apply-defaults.sh only runs on macOS, skipping."
    exit 0
fi

# Get the directory of the script itself. Avoid readlink -f, BSD doesn't have it.
script_dir=$(cd "$(dirname "$0")" && pwd -P)
. "$script_dir/domains.sh"

src_dir="$script_dir/defaults"

# Private and undocumented, but it rereads com.apple.symbolichotkeys and rebinds
# everything, so shortcuts work without logging out. Fall back rather than fail
# if a macOS update ever moves or drops it.
activate_settings=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings

post_apply() {
    case "$1" in
        com.apple.symbolichotkeys)
            if [ -x "$activate_settings" ]; then
                "$activate_settings" -u
            else
                echo "  activateSettings is missing; log out and back in to bind the shortcuts."
            fi
            ;;
        com.apple.dock)
            killall Dock 2> /dev/null || true
            ;;
    esac
}

echo "This overwrites your keyboard shortcuts with the checked-in set;"
echo "any shortcut never captured to the repo will be lost. Trackpad and"
echo "Dock settings are merged, and your Dock's apps are left alone."
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping..."
    exit 0
fi

for entry in "${domains[@]}"; do
    domain=${entry%%:*}
    mode=${entry##*:}
    src="$src_dir/$domain.plist"

    if [ ! -f "$src" ]; then
        echo "No defaults/$domain.plist, skipping $domain"
        continue
    fi

    case $mode in
        full-replace)
            defaults import "$domain" "$src"
            ;;
        merge)
            while IFS= read -r key; do
                [ -n "$key" ] || continue
                esc=${key//./\\.}
                frag=$(plutil -extract "$esc" xml1 -o - "$src")
                defaults write "$domain" "$key" "$frag"
            done <<< "$(plist_keys "$src")"
            ;;
        *)
            echo "Unknown mode '$mode' for $domain"
            exit 1
            ;;
    esac

    echo "Applied $domain"
    post_apply "$domain"
done

echo
echo "Done. Trackpad and scrolling changes only take effect after a logout."
