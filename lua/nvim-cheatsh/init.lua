local View = require("nvim-cheatsh.view")
local config = require("nvim-cheatsh.config")
local cheatsh = require("nvim-cheatsh.cheatsh")
local fzf = require("fzf-lua")

local Cheat = {}

local view

function Cheat.is_open()
  return view and view:is_valid() or false
end

function Cheat.setup(options)
  config.setup(options)
end

function Cheat.close()
  if Cheat.is_open() then
    view:close()
  end
end

local function get_ft_query(...)
  local args = { ... }
  -- if no arguments, open the list
  if #args == 0 then
    return {
      ft = "sh",
      query = "list",
    }
  end
  if vim.islist(args) and #args == 1 and type(args[1]) == "table" then
    args = args[1]
  end
  -- if there is only 1 argument, it is the query
  if #args == 1 then
    return {
      ft = "sh",
      query = args[1],
    }
  end
  -- if there are more than 1 argument, 1/2+3+4 are the query and the language
  if #args > 1 then
    local lang = args[1]
    local query = args[2]
    for i = 3, #args do
      query = query .. "+" .. args[i]
    end
    return {
      ft = lang,
      query = lang .. "/" .. query,
    }
  end
end

function Cheat.open(...)
  local ft_query = get_ft_query(...)
  if not Cheat.is_open() then
    view = View.create()
  end

  cheatsh.fetch_cheatsheet(ft_query.query, false, function(lines)
    view:set_option("modifiable", true)
    view:set_option("filetype", ft_query.ft)
    vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, lines)
    view:set_option("modifiable", false)
    -- go to the top of the buffer
    vim.api.nvim_win_set_cursor(view.win, { 1, 0 })
  end)
end

function Cheat.list()
  cheatsh.fetch_list(function(cheat_queries)
    fzf.fzf_exec(cheat_queries, {
      prompt = "cheat.sh> ",
      previewer = false,
      preview = {
        type = "cmd",
        fn = function(items)
          return string.format(
            "curl -s '%s%s'",
            config.options.cheatsh_url,
            items[1]
          )
        end,
      },
      actions = {
        default = function(selected)
          if selected[1] then
            Cheat.open(selected[1])
          end
        end,
      },
    })
  end)
end

return Cheat
