local M = {}

local cmd = vim.cmd
local api = vim.api

function M.nvim_create_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		api.nvim_command('augroup '..group_name)
		api.nvim_command('autocmd!')
		for _, def in ipairs(definition) do
			-- if type(def) == 'table' and type(def[#def]) == 'function' then
			-- 	def[#def] = lua_callback(def[#def])
			-- end
			local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
			api.nvim_command(command)
		end
		api.nvim_command('augroup END')
	end
end

M.file = require('utils.file')

return M
