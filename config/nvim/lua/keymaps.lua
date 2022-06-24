local M = {}

local opts = { noremap = true, silent = true }

local mode_adapters = {
	insert_mode = "i",
	normal_mode = "n",
	term_mode = "t",
	visual_mode = "v",
	visual_block_mode = "x",
	command_mode = "c",
	operator_pending_mode = "o",
	select_mode = "s",
	ic = "!",
	ic_lang_arg_mode = "l",
	nvso = "",
}

local generic_opts = {
	insert_mode = opts,
	normal_mode = opts,
	term_mode = opts,
	visual_mode = opts,
	visual_block_mode = opts,
	command_mode = { silent = false },
}

local keymappings = {
	term_mode = {
		["<C-o>"] = { "<C-\\><C-n>", { noremap = false, silent = false } },
	},
	normal_mode = {
		["<leader>v"] = "<cmd>tabnew $MYVIMRC<CR>",
		["<leader><leader>"] = "<C-^>",

		["<leader>tT"] = "<cmd>TestNearest<CR>",
		["<leader>tt"] = "<cmd>TestFile<CR>",
		["<leader>ta"] = "<cmd>TestSuite<CR>",
		["<leader>tl"] = "<cmd>TestLast<CR>",
		["<leader>tg"] = "<cmd>TestVisit<CR>",

		["<leader>n"] = "<cmd>lua require('utils.file').rename()<cr>",

		["<leader>gg"] = "<cmd>lua require('telescope.builtin').live_grep()<CR>",
		["<leader>gw"] = "<cmd>lua require('telescope.builtin').grep_string()<CR>",
		["<leader>ge"] = "<cmd>lua require('telescope.builtin').live_grep({cwd = require('telescope.utils').buffer_dir()})<CR>",
		["<leader>ga"] = "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'parts/', 'app/', 'lib/'}})<cr>",
		["<leader>gs"] = "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'spec/', 'test/'}})<cr>",
		["<leader>gc"] = "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'config/'}})<cr>",
		["<leader>gd"] = "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {vim.fn.input('Enter the directory to search: ', '', 'file')}})<cr>",

		["<leader>ff"] = "<cmd>lua require('telescope.builtin').find_files()<CR>",
		["<leader>fe"] = "<cmd>lua require('telescope.builtin').find_files({cwd = require('telescope.utils').buffer_dir()})<CR>",
		["<leader>fs"] = "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'spec/', 'test/'}})<CR>",
		["<leader>fa"] = "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'parts/', 'app/', 'lib/'}})<CR>",
		["<leader>fc"] = "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'config/'}})<CR>",

		["<leader>fb"] = "<cmd>Telescope buffers<cr>",
		["<leader>fgc"] = "<cmd>Telescope git_commits<cr>",
		["<leader>fgd"] = "<cmd>Telescope git_bcommits<cr>",

		["<leader>bb"] = "<cmd>lua require('telescope').extensions.file_browser.file_browser({hidden = true})<CR>",
		["<leader>be"] = "<cmd>lua require('telescope').extensions.file_browser.file_browser({hidden = true, cwd = require('telescope.utils').buffer_dir()})<CR>",

		["<leader>zn"] = "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>",
		["<leader>zo"] = "<Cmd>ZkNotes<CR>",
		["<leader>zt"] = "<Cmd>ZkTags<CR>",
		["<leader>zf"] = "<Cmd>ZkNotes { match = vim.fn.input('Search: ') }<CR>",
		-- ["<leader>zf"] = "<Cmd>Telescope zk notes<CR>",
	},
	insert_mode = {
		["<C-l>"] = { "<space>=><space>", { noremap = true } },

		["<Tab>"] = { "snippy#can_expand_or_advance() ? '<Plug>(snippy-expand-or-next)' : '<Tab>'", { expr = true } },
		["<S-Tab>"] = { "snippy#can_jump(-1) ? '<Plug>(snippy-previous)' : '<Tab>'", { expr = true } },
	},
	select_mode = {
		["<Tab>"] = { "snippy#can_jump(1) ? '<Plug>(snippy-next)' : '<Tab>'", { expr = true } },
		["<S-Tab>"] = { "snippy#can_jump(-1) ? '<Plug>(snippy-previous)' : '<Tab>'", { expr = true } },
	},
	visual_mode = {
		["<leader>zf"] = ":'<,'>ZkMatch<CR>",
	},
	visual_block_mode = {
		["<Tab>"] = "<Plug>(snippy-cut-text)",
	},
	command_mode = {
		["%%"] = { "expand('%:h').'/'", { expr = true, noremap = true } },
	},
}

local lsp_keymappings = {
	normal_mode = {
		["gD"] = "<Cmd>lua vim.lsp.buf.declaration()<CR>",
		["gd"] = "<Cmd>Telescope lsp_definitions<CR>",
		["K"] = "<Cmd>lua vim.lsp.buf.hover()<CR>",
		["gi"] = "<cmd>Telescope lsp_implementations<CR>",
		["<C-k>"] = "<cmd>lua vim.lsp.buf.signature_help()<CR>",
		["<space>wa"] = "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
		["<space>wr"] = "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
		["<space>wl"] = "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
		["<space>D"] = "<cmd>Telescope lsp_type_definitions<CR>",
		["<space>rn"] = "<cmd>lua vim.lsp.buf.rename()<CR>",
		["<space>ca"] = "<cmd>lua vim.lsp.buf.code_action()<CR>",
		["gr"] = "<cmd>Telescope lsp_references<CR>",
		["<space>e"] = "<cmd>lua vim.diagnostic.open_float()<CR>",
		["[d"] = "<cmd>lua vim.diagnostic.goto_prev()<CR>",
		["]d"] = "<cmd>lua vim.diagnostic.goto_next()<CR>",
		["<space>q"] = "<cmd>lua vim.diagnostic.setloclist()<CR>",
		["<space>dd"] = "<cmd>Telescope diagnostics bufnr=0<CR>",
		["<space>dD"] = "<cmd>Telescope diagnostics<CR>",
	},
}

function M.set_keymap(mode, lhs, rhs)
	local opt = generic_opts[mode] and generic_opts[mode] or opts
	if type(rhs) == "table" then
		opt = rhs[2]
		rhs = rhs[1]
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, opt)
end

function M.set_buf_keymap(bufnr, mode, lhs, rhs)
	local opt = generic_opts[mode] and generic_opts[mode] or opts
	if type(rhs) == "table" then
		opt = rhs[2]
		rhs = rhs[1]
	end
	vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opt)
end

function M.buf_map(buf, mode, keymaps)
	mode = mode_adapters[mode] and mode_adapters[mode] or mode
	for lhs, rhs in pairs(keymaps) do
		M.set_buf_keymap(buf, mode, lhs, rhs)
	end
end

function M.map(mode, keymaps)
	mode = mode_adapters[mode] and mode_adapters[mode] or mode
	for lhs, rhs in pairs(keymaps) do
		M.set_keymap(mode, lhs, rhs)
	end
end

function M.setup()
	for mode, mapping in pairs(keymappings) do
		M.map(mode, mapping)
	end
end

function M.setup_lsp_mappings(bufnr)
	for mode, mapping in pairs(lsp_keymappings) do
		M.buf_map(bufnr, mode, mapping)
	end
end

return M
