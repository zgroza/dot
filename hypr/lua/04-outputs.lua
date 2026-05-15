hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.exec_cmd("pidof shikane || shikane")

-- Workspace Rules
hl.workspace_rule({ workspace = "10", default_name = "term" })
