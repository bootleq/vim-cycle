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
local content_width = 0
local items_size = 0
local picker_padding = 6

local M = {}

local flex_width = function(self, max_columns, max_lines)
  local width = content_width + picker_padding * 2
  width = math.max(width, 20)
  width = math.min(width, math.floor(max_columns * 0.9))
  return width
end

local flex_height = function(self, max_columns, max_lines)
  local height = items_size + picker_padding
  height = math.max(height, 10)
  height = math.min(height, math.floor(max_lines * 0.9))
  return height
end

local defaults = themes.get_cursor{
  layout_config = {
    width = flex_width,
    height = flex_height,
  },
}

local config = vim.tbl_extend('force', {}, defaults)

M.setup = function(opts)
  config = vim.tbl_deep_extend('force', defaults, opts or {})
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

  local widths = {
    text = 0,
    hint = 0,
    group_name = 0,
  }
  for idx, item in ipairs(items) do
    widths.text = math.max(widths.text , strings.strdisplaywidth(item.text))
    widths.hint = math.max(widths.hint, strings.strdisplaywidth(item.hint))
    widths.group_name = math.max(widths.group_name, strings.strdisplaywidth(item.group_name))
  end
  content_width = widths.text + widths.hint + widths.group_name + (widths.hint > 0 and hint_pad_size or 0) + (widths.group_name > 0 and 2 or 0)
  items_size = #items

  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = widths.text },
      { width = widths.hint > 0 and hint_pad_size or 1 },
      { width = widths.hint },
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
