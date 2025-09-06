local M = {}
local hint_pad_size = 4

local make_select_options = function(options)
  local max_length = math.max(
    unpack(
      vim.tbl_map(function(opt)
        return string.len(opt.text)
      end, options)
    )
  )

  local max_hint_length = math.max(
    unpack(
      vim.tbl_map(function(opt)
        return string.len(opt.hint)
      end, options)
    )
  )

  local hint_pad = ''
  if max_hint_length > 0 then
    hint_pad = string.rep(' ', hint_pad_size)
  end

  local format_str = string.format("%%-%dS" .. hint_pad .. " %%-%dS", max_length, max_hint_length)

  local select_options = {
    prompt = 'Cycle to:',
    format_item = function(opt)
      local group
      if string.len(opt.group_name) > 0 then
        group = string.format(' (%s)', opt.group_name)
      else
        group = ''
      end

      return vim.fn.printf(format_str, opt.text, opt.hint) .. group
    end,
  }

  return select_options
end

M.select = function(options, ctx)
  local select_options = make_select_options(options)

  vim.ui.select(
    options,
    select_options,
    function(_, idx)
      vim.call(ctx.sid .. 'on_select', idx, ctx)
    end
  )
end

M.conflict_select = function(options, ctx)
  local select_options = make_select_options(options)

  vim.ui.select(
    options,
    select_options,
    function(_, idx)
      vim.call(ctx.sid .. 'on_resolve_conflict', idx, ctx)
    end
  )
end

return M
