local M = {}

M.get_node_range = function()
  local node =  vim.treesitter.get_node()

  if node then
    local range = vim.treesitter.get_node_range(node)
    local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node)

    return {
      { start_row + 1, start_col + 1 },
      { end_row + 1, end_col },
    }
  end

  return {}
end

return M
