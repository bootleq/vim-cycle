local M = {}

M.conflict_select = function(options, ctx)
  local max_length = math.max(
    unpack(
      vim.tbl_map(function(opt)
        return string.len(opt.text)
      end, options)
    )
  )
  local format_str = string.format("%%-%ds", max_length)

  local select_options = {
    prompt = 'Cycle to:',
    format_item = function(opt)
      local group
      if string.len(opt.group_name) > 0 then
        group = string.format(' (%s)', opt.group_name)
      else
        group = ''
      end

      return string.format(format_str, opt.text) .. group
    end,
  }

  vim.ui.select(
    options,
    select_options,
    function(_, idx)
      vim.call(ctx.sid .. 'on_resolve_conflict', idx, ctx)
    end
  )
end

return M
