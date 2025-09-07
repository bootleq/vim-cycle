local strings = require 'plenary.strings'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local themes = require 'telescope.themes'
local make_entry = require 'telescope.make_entry'
local entry_display = require 'telescope.pickers.entry_display'

local hint_pad_size = 2

local M = {}

local defaults = themes.get_cursor{
  layout_config = {
    width = { 0.5, min = 25, max = 78},
    height = { 0.5, min = 5, max = 24},
  },
}

local config = vim.tbl_extend('force', {}, defaults)

M.setup = function(opts)
  config = vim.tbl_deep_extend('force', defaults, opts or {})
end

function max_len(items, prop)
  local max_len = math.max(
    unpack(
      vim.tbl_map(function(opt)
        return strings.strdisplaywidth(opt[prop])
      end, items)
    ))
  return max_len
end

function picker(type, items, ctx)
  local opts = config

  local title = ''
  local callback = ''
  if type == 'select' then
    title = 'Cycle'
    callback = ctx.sid .. 'on_select'
  elseif type == 'conflict' then
    title = 'Conflict'
    callback = ctx.sid .. 'on_resolve_conflict'
  end

  local max_text_len = max_len(items, 'text')
  local max_hint_len = max_len(items, 'hint')

  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = max_text_len },
      { width = max_hint_len > 0 and hint_pad_size or 1 },
      { width = max_hint_len },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    local v = entry.value
    local group_name = v.group_name
    if #group_name > 0 then
      group_name = string.format('(%s)', group_name)
    end
    return displayer {
      { v.text },
      '',
      { v.hint, 'TelescopeResultsFunction' },
      { group_name, 'TelescopeResultsComment' },
    }
  end

  local entry_maker = function(entry)
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = entry.text,
      display = make_display,
    }, opts)
  end

  pickers
    .new(opts, {
      prompt_title = title,
      finder = finders.new_table {
        results = items,
        entry_maker = entry_maker,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            vim.call(callback, selection.index, ctx)
            return
          end
        end)

        return true
      end,
    })
    :find()

end

M.select = function(items, ctx)
  picker('select', items, ctx)
end

M.conflict_select = function(items, ctx)
  picker('conflict', items, ctx)
end

return M
