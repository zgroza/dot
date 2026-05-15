local vars = require("lua/00-variables")
local mainMod = vars.mainMod
local term = vars.term
local launcher = vars.launcher

hl.config({
    binds = {
        workspace_back_and_forth = true
    }
})

-- Basic binds
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(launcher))
hl.bind("ALT + Space", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.group.toggle())
hl.bind(mainMod .. " + bracketleft", hl.dsp.group.prev())
hl.bind(mainMod .. " + bracketright", hl.dsp.group.next())
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- Focus movement
local directions = { 
    Left = "l", Right = "r", Up = "u", Down = "d", 
    H = "l", L = "r", K = "u", J = "d" 
}
for key, dir in pairs(directions) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir, group_aware = true }))
end

-- Switch workspaces
for i = 1, 8 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind(mainMod .. " + E", hl.dsp.focus({ workspace = "5" }))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.window.move({ workspace = "5" }))

local f_keys = { "F1", "F2", "F3", "F4" }
for _, key in ipairs(f_keys) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = key }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = key }))
end

hl.bind(mainMod .. " + W", hl.dsp.focus({ workspace = "10" }))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.window.move({ workspace = "10" }))

hl.bind(mainMod .. " + Comma", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + Period", hl.dsp.focus({ workspace = "e+1" }))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy && wl-paste > /dev/shm/Screenshot-$(date +%F_%T).png'))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("grimshot copy active"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { repeating = true })

-- Playback
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl previous"), { locked = true })

-- Caps Lock
hl.bind("Caps_Lock", hl.dsp.exec_cmd("swayosd-client --caps-lock"), { release = true })

-- Waybar toggle
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- Notification Center
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- Session management
local exit_cmd = hl.dsp.exit()
local f = io.popen("which hyprshutdown 2>/dev/null")
if f then
    if f:read("*a") ~= "" then
        exit_cmd = hl.dsp.exec_cmd("hyprshutdown")
    end
    f:close()
end
hl.bind(mainMod .. " + SHIFT + Q", exit_cmd)
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))

-- Shortcuts disabled mode
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.submap("shortcuts_disabled"))
hl.define_submap("shortcuts_disabled", function()
    hl.bind(mainMod .. " + SHIFT + X", hl.dsp.submap("reset"))
    hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }))
end)

-- Mouse binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
