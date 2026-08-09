#!/usr/bin/env bash
#
# The table of macOS defaults domains this repo tracks, shared by
# capture-defaults.sh and apply-defaults.sh. Not meant to be run directly.
#
# Modes decide how a domain is written back:
#
#   full-replace  the whole domain is captured, and applied with
#                 `defaults import`. Removals propagate, which is what we want
#                 for shortcuts: unbinding one in System Settings should unbind
#                 it everywhere.
#   merge         only part of the domain is captured, so it is applied key by
#                 key and anything untracked on the target machine survives.
#                 `defaults import` here would delete the untracked keys --
#                 for the Dock that means every app in it.

domains=(
    "com.apple.symbolichotkeys:full-replace"
    "com.apple.dock:merge"
    "com.apple.AppleMultitouchTrackpad:merge"
    "com.apple.driver.AppleBluetoothMultitouch.trackpad:merge"
    "NSGlobalDomain:merge"
)

# Keys dropped on capture. The Dock's app lists are deliberately untracked --
# they differ per machine and that is the point -- and the rest are counters and
# locale that macOS rewrites on its own, which would turn every diff into noise.
strip_keys() {
    case "$1" in
        com.apple.dock)
            echo "persistent-apps persistent-others recent-apps"
            echo "mod-count trash-full last-analytics-stamp lastShowIndicatorTime"
            echo "loc region version"
            ;;
        com.apple.AppleMultitouchTrackpad | com.apple.driver.AppleBluetoothMultitouch.trackpad)
            # Schema version maintained by macOS, not a setting.
            echo "version"
            ;;
    esac
}

# NSGlobalDomain is thousands of keys of per-app state, so it gets a whitelist
# rather than a blocklist. Everything here is trackpad/scrolling behaviour or a
# window animation duration.
keep_keys() {
    case "$1" in
        NSGlobalDomain)
            echo "AppleEnableSwipeNavigateWithScrolls"
            echo "com.apple.mouse.scaling"
            echo "com.apple.swipescrolldirection"
            echo "com.apple.trackpad.forceClick"
            echo "com.apple.trackpad.scaling"
            echo "NSWindowResizeTime"
            echo "NSAutomaticWindowAnimationsEnabled"
            ;;
    esac
}

# Top-level keys of a plist file. Every tracked merge domain holds flat scalars,
# so parsing `plutil -p` at its two-space top-level indent is enough; nested
# values would appear indented further and be skipped.
plist_keys() {
    plutil -p "$1" | sed -n 's/^  "\(.*\)" => .*/\1/p'
}
