local function extend(base, override)
  local result = {}
  for k, v in pairs(base or {}) do result[k] = v end
  for k, v in pairs(override or {}) do result[k] = v end
  return result
end

local common_opts = {
  float = true,
  center = true,
  size = {
    "monitor_w * 0.7",
    "monitor_h * 0.7",
  },
}

hl.window_rule(extend(common_opts, { match = { title = "^nmtui$", }, }))
hl.window_rule(extend(common_opts, { match = { class = "^org.pulseaudio.pavucontrol$", }, }))
hl.window_rule(extend(common_opts, { match = { class = "^blueman-manager$", }, }))
hl.window_rule(extend(common_opts, { match = { class = "^nm-connection-editor$", }, }))
hl.window_rule({
  match = { title = "^Unlock Database - KeePassXC$", },
  float = true,
  stay_focused = true,
})
hl.window_rule({ match = { title = "^WPRS.*$", }, float = true, })
hl.window_rule({
  match = { class = "^xdg-desktop-portal-gtk$", },
  float = true,
  center = true,
  stay_focused = true,
})
hl.window_rule({ match = { title = "^Picture in picture$", }, float = true, pin = true, })
