local function set_servername()
  local servername = vim.v.servername
  if servername then
    local file = io.open("/tmp/nvim", "w")
    if file then
      file:write(servername)
      file:close()
      print("Set /tmp/nvim to " .. servername)
    else
      print("Error: Could not open /tmp/nvim for writing")
    end
  else
    print("Error: servername is not set")
  end
end

vim.keymap.set("n", "<leader>nv", set_servername, { desc = "Set /tmp/nvim to servername" })
