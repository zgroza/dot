local M = {}

M.mainMod = "SUPER"
M.term = "kitty"
M.launcher = 'zsh -i -c "pkill rofi || rofi -show combi"'

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GTK_THEME", "adw-gtk3-dark")

return M
