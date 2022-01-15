local M = {}

local function get_capabilities()
	return require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())
end

local function on_attach(_, bufnr)
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
	require("keymaps").setup_lsp_mappings(bufnr)
end

local function disable_format(next)
	return function(client, bufnr)
		next(client, bufnr)
		client.resolved_capabilities.document_formatting = false
		client.resolved_capabilities.document_range_formatting = false
	end
end

local function format_on_save(next)
	return function(client, bufnr)
		next(client, bufnr)
		vim.api.nvim_command([[augroup Format]])
		vim.api.nvim_command([[autocmd! * <buffer>]])
		vim.api.nvim_command([[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]])
		vim.api.nvim_command([[augroup END]])
	end
end

local lsp_configs = {
	["sumneko_lua"] = require("lua-dev").setup(),
	["solargraph"] = {
		on_attach = disable_format(on_attach),
		init_options = {
			formatting = false,
		},
		settings = {
			solargraph = {
				diagnostics = true,
			},
		},
	},
	["rust_analyzer"] = {
		on_attach = format_on_save(on_attach),
	},
}

local function setup_lsp_config(provider)
	local config = {
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 50,
		},
		capabilities = get_capabilities(),
	}

	if lsp_configs[provider] then
		config = vim.tbl_extend("force", config, lsp_configs[provider])
	end

	return config
end

function M.setup()
	local lsp_installer = require("nvim-lsp-installer")

	lsp_installer.on_server_ready(function(server)
		server:setup(setup_lsp_config(server.name))
	end)

	require("null-ls").setup({
		on_attach = function(client, bufnr)
			local keymaps = require("keymaps")
			if client.resolved_capabilities.document_formatting then
				keymaps.set_buf_keymap(bufnr, "n", "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
			end
			if client.resolved_capabilities.document_range_formatting then
				keymaps.set_buf_keymap(bufnr, "n", "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
			end
		end,
		flags = {
			debounce_text_changes = 50,
		},
		capabilities = get_capabilities(),
		sources = {
			require("null-ls").builtins.formatting.stylua,
			require("null-ls").builtins.formatting.standardrb,
			require("null-ls").builtins.formatting.eslint_d.with({ extra_filetypes = { "svelte" } }),
			require("null-ls").builtins.diagnostics.eslint_d.with({ extra_filetypes = { "svelte" } }),
			require("null-ls").builtins.code_actions.eslint_d.with({ extra_filetypes = { "svelte" } }),
			require("null-ls").builtins.code_actions.gitsigns,
			require("null-ls").builtins.completion.spell,
		},
	})
end

return M
