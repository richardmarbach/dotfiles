local M = {}

local snippy = require("snippy")
local cmp = require("cmp")

function M.setup()
	snippy.setup({
		mappings = {
			is = {
				["<Tab>"] = "expand_or_advance",
				["<S-Tab>"] = "previous",
			},
			nx = {
				["<leader>x"] = "cut_text",
			},
		},
	})

	cmp.setup({
		completion = {
			autocomplete = false,
			completeopt = "menu,menuone,noselect",
		},
		snippet = {
			expand = function(args)
				snippy.expand_snippet(args.body)
			end,
		},
		mapping = {
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-n>"] = cmp.mapping.select_next_item(),
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-y>"] = cmp.mapping.confirm({ select = false }),
			["<C-e>"] = cmp.mapping.close(),
			["<C-Space>"] = cmp.mapping.confirm(),
		},
		sources = {
			{ name = "github" },
			-- { name = "nvim_lsp" },
			-- { name = "buffer", max_item_count = 10 },
			-- { name = "snippy" },
			-- { name = "path" },
		},
		experimental = {
			ghost_text = true,
		},
	})
end

function M.complete()
	cmp.complete()
end

function M.snippet()
	cmp.complete({
		config = {
			sources = {
				{ name = "snippy" },
			},
		},
	})
end

vim.cmd([[
  inoremap <C-x><C-o> <Cmd>lua require('config/cmp').complete()<CR>
  inoremap <C-x><C-s> <Cmd>lua require('config/cmp').snippet()<CR>
]])

return M
