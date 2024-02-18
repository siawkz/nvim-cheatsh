local View = require("nvim-cheatsh.view")
local config = require("nvim-cheatsh.config")
local cheatsh = require("nvim-cheatsh.cheatsh")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

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
  if vim.tbl_islist(args) and #args == 1 and type(args[1]) == "table" then
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

local function cheat_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry)
      local ft_query = get_ft_query(entry.value)
      cheatsh.fetch_cheatsheet(ft_query.query, true, function(lines)
        if not self.state.bufnr or not vim.api.nvim_buf_is_valid(self.state.bufnr) then
          return
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end)
    end,
  })
end

function Cheat.list()
  local opts = {}
  cheatsh.fetch_list(function(cheat_queries)
    pickers
      .new(opts, {
        prompt_title = "cheat.sh",
        finder = finders.new_table({
          results = cheat_queries,
          entry_maker = function(entry)
            if string.find(entry, "/") then
              return {
                value = {
                  string.sub(entry, 1, string.find(entry, "/") - 1),
                  string.sub(entry, string.find(entry, "/") + 1),
                },
                display = entry,
                ordinal = entry,
              }
            end
            return {
              value = entry,
              display = entry,
              ordinal = entry,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = cheat_previewer(),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            if selection then
              actions.close(prompt_bufnr)
              Cheat.open(selection.value)
            end
          end)
          return true
        end,
      })
      :find()
  end)
end

return Cheat
