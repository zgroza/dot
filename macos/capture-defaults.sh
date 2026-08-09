#!/usr/bin/env bash
set -euo pipefail

# Exports the tracked defaults domains over their checked-in copies.
#
# Run this after changing anything this repo tracks: keyboard shortcuts,
# trackpad, Dock. System Settings stays the editor and these plists are only the
# record of what it produced, which saves hand-writing things like
# symbolichotkeys' modifier bitmasks. See domains.sh for what is tracked.

if [ "$(uname -s)" != "Darwin" ]; then
    echo "capture-defaults.sh only runs on macOS, skipping."
    exit 0
fi

# Get the directory of the script itself. Avoid readlink -f, BSD doesn't have it.
script_dir=$(cd "$(dirname "$0")" && pwd -P)
. "$script_dir/domains.sh"

out_dir="$script_dir/defaults"
mkdir -p "$out_dir"

for entry in "${domains[@]}"; do
    domain=${entry%%:*}
    out="$out_dir/$domain.plist"
    keep=$(keep_keys "$domain")

    if [ -n "$keep" ]; then
        # Whitelist: start from an empty dict and copy the wanted keys over,
        # which preserves each one's type.
        tmp=$(mktemp -t capture-defaults)
        defaults export "$domain" - > "$tmp"
        plutil -create xml1 "$out"
        for key in $keep; do
            # plutil reads an unescaped dot as a keypath separator, and half of
            # these keys are named com.apple.something.
            esc=${key//./\\.}
            frag=$(plutil -extract "$esc" xml1 -o - "$tmp" 2> /dev/null) || continue
            plutil -insert "$esc" -xml "$frag" "$out"
        done
        rm -f "$tmp"
    else
        # Export to stdout rather than to the path directly: given a file
        # argument `defaults export` writes a binary plist, and only the `-`
        # form emits XML. Binary round-trips fine but is useless in a diff.
        defaults export "$domain" - > "$out"
        for key in $(strip_keys "$domain"); do
            plutil -remove "$key" "$out" 2> /dev/null || true
        done
    fi

    echo "Captured $domain -> defaults/$domain.plist"
done
