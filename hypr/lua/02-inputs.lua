local vars = require("lua/00-variables")

hl.config({
    input = {
        kb_layout = "pl",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0.5,
        accel_profile = "adaptive",
        touchpad = {
            natural_scroll = false,
            tap_to_click = true
        }
    }
})

-- Default 3-finger swipe for workspaces
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Custom gestures mapping
hl.gesture({
    fingers = 4,
    direction = "left",
    action = function() hl.dispatch(hl.dsp.group.prev()) end
})

hl.gesture({
    fingers = 4,
    direction = "right",
    action = function() hl.dispatch(hl.dsp.group.next()) end
})

hl.gesture({
    fingers = 3,
    direction = "up",
    action = function() hl.exec_cmd(vars.launcher) end
})

hl.gesture({
    fingers = 3,
    direction = "down",
    action = function() hl.exec_cmd(vars.launcher) end
})
