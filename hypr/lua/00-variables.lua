local M = {}

M.mainMod = "SUPER"
M.term = "kitty"
M.launcher = 'zsh -i -c "pkill rofi || rofi -show combi"'

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

return M
