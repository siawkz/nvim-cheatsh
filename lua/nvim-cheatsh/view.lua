local config = require("nvim-cheatsh.config")

local View = {}
View.__index = View

local function find_rogue_buffer()
  for _, v in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.bufname(v) == "Cheat" then
      return v
    end
  end
  return nil
end

---Find pre-existing Cheat buffer, delete its windows then wipe it.
---@private
local function wipe_rogue_buffer()
  local bn = find_rogue_buffer()
  if bn then
    local win_ids = vim.fn.win_findbuf(bn)
    for _, id in ipairs(win_ids) do
      if vim.fn.win_gettype(id) ~= "autocmd" and vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_close(id, true)
      end
    end

    vim.api.nvim_buf_set_name(bn, "")
    vim.schedule(function()
      pcall(vim.api.nvim_buf_delete, bn, {})
    end)
  end
end

function View:new(opts)
  opts = opts or {}

  local this = {
    buf = vim.api.nvim_get_current_buf(),
    win = opts.win or vim.api.nvim_get_current_win(),
    items = {},
  }
  setmetatable(this, self)
  return this
end

function View:set_option(name, value, win)
  if win then
    return vim.api.nvim_set_option_value(name, value, { win = self.win, scope = "local" })
  else
    return vim.api.nvim_set_option_value(name, value, { buf = self.buf })
  end
end

function View:is_valid()
  return vim.api.nvim_buf_is_valid(self.buf) and vim.api.nvim_buf_is_loaded(self.buf)
end

function View:setup()
  vim.cmd("setlocal nonu")
  vim.cmd("setlocal nornu")
  if not pcall(vim.api.nvim_buf_set_name, self.buf, "Cheat") then
    wipe_rogue_buffer()
    vim.api.nvim_buf_set_name(self.buf, "Cheat")
  end
  self:set_option("bufhidden", "wipe")
  self:set_option("buftype", "nofile")
  self:set_option("swapfile", false)
  self:set_option("cursorline", true, true)
  self:set_option("buflisted", false)

  if config.options.position == "top" or config.options.position == "bottom" then
    vim.api.nvim_win_set_height(self.win, config.options.height)
  else
    vim.api.nvim_win_set_width(self.win, config.options.width)
  end

  self:set_option("filetype", "Cheat")
end

function View:close()
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  if vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_delete(self.buf, {})
  end
end

function View.create()
  local view
  vim.api.nvim_win_call(0, function()
    vim.cmd("below new")
    local pos = { bottom = "J", top = "K", left = "H", right = "L" }
    vim.cmd("wincmd " .. (pos[config.options.position] or "K"))
    view = View:new()
    view:setup()
  end)

  return view
end

return View
