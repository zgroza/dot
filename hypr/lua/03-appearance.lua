hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 0,
        layout = "dwindle"
    },
    decoration = {
        rounding = 0,
        shadow = { enabled = false },
        blur = { enabled = false }
    },
    group = {
        groupbar = {
            enabled = true,
            font_family = "AtkynsonMono Nerd Font",
            font_size = 12,
            font_weight_active = "bold",
            font_weight_inactive = "bold",
            text_color = "rgba(cdd6f4ff)",
            col = {
                active = "rgba(cba6f7ff)",
                inactive = "rgba(313244ff)"
            },
            height = 20
        }
    }
})

-- Curves
hl.curve("simple", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })

-- Animations
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "simple", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "simple", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "simple" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "simple", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "simple", style = "slidevert" })
