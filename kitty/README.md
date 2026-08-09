# kitty layout

kitty splits itself, no help from the link script needed. `kitty.conf` ends with

```conf
globinclude os/${KITTY_OS}.conf
```

and kitty sets `KITTY_OS` to `linux`, `macos` or `bsd` while processing
includes. `globinclude` rather than `include`, because a glob matching nothing
is quiet whereas a missing `include` logs a warning.

`open-actions.conf` ignores `include` and `globinclude` entirely, so the
`xdg-open` vs `open` difference goes through an `action_alias` that dispatches
on whichever opener the system has.
