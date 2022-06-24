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
  ["tsserver"] = {
    on_attach = disable_format(on_attach),
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

  local null_ls = require("null-ls")
  null_ls.setup({
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
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.standardrb,
      null_ls.builtins.formatting.eslint.with({ extra_filetypes = { "svelte" } }),
      null_ls.builtins.diagnostics.eslint.with({ extra_filetypes = { "svelte" } }),
      null_ls.builtins.code_actions.eslint.with({ extra_filetypes = { "svelte" } }),
      null_ls.builtins.code_actions.gitsigns,
      null_ls.builtins.completion.spell,

      null_ls.builtins.diagnostics.shellcheck,
      null_ls.builtins.formatting.shellharden,
      null_ls.builtins.formatting.shfmt,

      null_ls.builtins.formatting.pg_format,
    },
  })
end

return M
