# macOS settings

macOS has no plaintext config for keyboard shortcuts, trackpad or Dock
settings. They are `defaults` domains, and the shortcuts in particular are grim:
`com.apple.symbolichotkeys` is keyed by opaque numeric IDs, with each binding
stored as `(ascii code, virtual keycode, modifier bitmask)`. The window tiling
section added in recent releases is in there too. Writing that by hand is
miserable, so this directory captures and replays the domains instead of
describing them:

```zsh
./macos/capture-defaults.sh   # System Settings -> macos/defaults/*.plist
./macos/apply-defaults.sh     # macos/defaults/*.plist -> System Settings
```

System Settings stays the editor. Change something there, run
`capture-defaults.sh`, and commit the diff — the plists are plain XML, so the
diff shows exactly which key moved.

## What is tracked

`domains.sh` is the table, shared by both scripts. Two modes, because the safe
choice differs per domain:

| Domain | Mode | Notes |
| --- | --- | --- |
| `com.apple.symbolichotkeys` | full-replace | every system shortcut, tiling included |
| `com.apple.dock` | merge | settings only, app lists stripped |
| `com.apple.AppleMultitouchTrackpad` | merge | built-in trackpad |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | merge | Magic Trackpad |
| `NSGlobalDomain` | merge | whitelisted keys only |

- **full-replace** applies with `defaults import`, which replaces the whole
  domain. That is deliberate for shortcuts: unbinding one in System Settings
  should unbind it on every machine. The cost is that a shortcut never captured
  to the repo is lost on the next apply, so the script asks before running.
- **merge** writes key by key and leaves untracked keys alone. The Dock needs
  this — its `persistent-apps` key *is* the list of apps in the Dock, and an
  import would wipe it. Counters and locale that macOS rewrites on its own are
  stripped too, otherwise every diff is noise.

`NSGlobalDomain` is a whitelist rather than a blocklist, since it holds
thousands of keys of per-app state. It tracks the handful that are trackpad and
scrolling behaviour, plus the window animation durations.

Only the system shortcuts are captured. The App Shortcuts pane is a different
mechanism — `NSUserKeyEquivalents`, per-app, keyed by menu item title — and is
unused here.

## macOS quirks worked around in the scripts

- `defaults export` writes a *binary* plist when given a file argument. Only the
  `-` stdout form emits XML, which is the whole point of checking it in.
- `plutil` reads an unescaped dot in a key name as a keypath separator, and half
  the `NSGlobalDomain` keys are named `com.apple.something`.
- Imported shortcuts do not bind until logout unless
  `.../SystemAdministration.framework/Resources/activateSettings -u` runs
  afterwards. It is private and undocumented, so the script falls back to
  telling you to log out if a macOS update ever removes it. Trackpad and
  scrolling changes need a logout regardless.

XML rather than JSON on purpose: `defaults import` refuses to parse JSON, the
round trip silently turns whole-number reals into integers, and JSON cannot
represent `<data>` or `<date>` at all — which any domain added later is likely
to contain.
