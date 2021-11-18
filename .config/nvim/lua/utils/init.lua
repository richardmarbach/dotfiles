local M = {}

local cmd = vim.cmd

function M.create_augroup(name, autocmds)
  cmd('augroup '..name)
  cmd('autocmd!')
  for _, autocmd in ipairs(autocmds) do
    if type(autocmd) == 'string' then
      cmd(autocmd)
    else
      cmd('autocmd ' .. table.concat(autocmd, ' '))
    end
  end

  cmd('augroup END')
end

M.file = require('utils.file')

function M.require_modules(base)
  for _, module in pairs(M.file.list_modules(base)) do
    if module ~= base..'/init.lua' then
      require(module).setup()
    end
  end
end

return M
