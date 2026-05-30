local vars = require("lua/00-variables")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland")
    hl.exec_cmd("systemctl --user import-environment XDG_CURRENT_DESKTOP XDG_SESSION_TYPE WAYLAND_DISPLAY DISPLAY")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("playerctld daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("waybar")
    hl.exec_cmd("arch-update --tray")
    hl.exec_cmd("sleep 5 && keepassxc --minimized")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent"
      .. " || " ..
      "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
      .. " || " ..
      "/usr/lib/polkit-kde-authentication-agent-1")
end)

hl.on("config.reloaded", function()
  hl.exec_cmd("pidof waybar || waybar")
end)

