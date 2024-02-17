local defaults = {
  cheatsh_url = "https://cht.sh/",
  position = "bottom", -- position of the window can be: bottom, top, left, right
  height = 20, -- height of the cheat when position is top or bottom
  width = 100, -- width of the cheat when position is left or right
}

local M = {}

M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
