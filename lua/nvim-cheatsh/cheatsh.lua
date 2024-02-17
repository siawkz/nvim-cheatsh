local config = require("nvim-cheatsh.config")

local M = {}

local function strip_ansi(str)
  return str:gsub("\x1b%[[0-9;]*m", "")
end

function M.fetch_cheatsheet(query, silent, callback)
  local url = config.options.cheatsh_url
  local cmd = "curl -s '" .. url .. query .. "'"
  if not silent then
    vim.notify("Fetching cheatsheet for " .. query, vim.log.levels.INFO, { title = "Cheatsh" })
  end
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, lines)
      if not lines or #lines == 0 then
        if not silent then
          vim.notify("No cheatsheet found for " .. query, vim.log.levels.WARN, { title = "Cheatsh" })
        end
        callback("sh", {})
        return
      end
      local success, result = pcall(function()
        for i, line in ipairs(lines) do
          lines[i] = strip_ansi(line)
        end
        callback(lines)
      end)
      if not success then
        vim.notify("Error processing cheatsheet: " .. result, vim.log.levels.ERROR, { title = "Cheatsh" })
        callback("sh", {})
      end
    end,
    stdout_buffered = true,
  })
end

function M.fetch_list(callback)
  local url = config.options.cheatsh_url
  url = url .. ":list"

  local cmd = "curl -s '" .. url .. "'"
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if not data then
        callback({})
        return
      end
      -- Split the list on new lines and remove ANSI color codes
      local lines = vim.split(table.concat(data, "\n"), "\r?\n")
      for i, line in ipairs(lines) do
        lines[i] = strip_ansi(line)
      end
      callback(lines)
    end,
    stdout_buffered = true,
  })
end

return M
