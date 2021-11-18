local M = {}

local fn = vim.fn

function M.rename()
  local old_name = fn.expand('%')
  local new_name = fn.input('New file name: ', fn.expand('%'), 'file')
  if new_name ~= '' and new_name ~= old_namea then
    vim.cmd(':keepalt saveas ' .. new_name)
    vim.cmd(':silent !rm ' .. old_name)
    vim.cmd(':bd ' .. old_name)
    vim.cmd('redraw!')
  end
end

function M.list_modules(base)
  local modules = {}

  local paths = {
    'lua/' .. base .. '/*',
    'lua/' .. base .. '/*/',
  }

  for _, path in ipairs(paths) do
    for _, module in ipairs(vim.api.nvim_get_runtime_file(path, true)) do
      module = string.gsub(module, '^.*/lua/'..base, base)
      module = string.gsub(module, ".lua$", "")
      module = string.gsub(module, "/$", "")
      table.insert(modules, module)
    end
  end
  return modules
end

return M
