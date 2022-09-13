local mason_status_ok, mason = pcall(require, "mason")
if not mason_status_ok then
  return
end

local lspconfig_status_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if not lspconfig_status_ok then
  return
end

mason.setup()
mason_lspconfig.setup({
  ensure_installed = {
    "sumneko_lua",
    "rust_analyzer",
  },
})

local status_ok, lsp = pcall(require, "lspconfig")
if not status_ok then
  return
end

local function get_capabilities()
  return require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())
end

local function on_attach(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  local bufopts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", bufopts)
  vim.keymap.set("n", "gd", "<Cmd>Telescope lsp_definitions<CR>", bufopts)
  vim.keymap.set("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", bufopts)
  vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", bufopts)
  vim.keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", bufopts)
  vim.keymap.set("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", bufopts)
  vim.keymap.set("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", bufopts)
  vim.keymap.set("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", bufopts)
  vim.keymap.set("n", "<space>D", "<cmd>Telescope lsp_type_definitions<CR>", bufopts)
  vim.keymap.set("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", bufopts)
  vim.keymap.set("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", bufopts)
  vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", bufopts)
  vim.keymap.set("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>", bufopts)
  vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", bufopts)
  vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", bufopts)
  vim.keymap.set("n", "<space>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", bufopts)
  vim.keymap.set("n", "<space>dd", "<cmd>Telescope diagnostics bufnr=0<CR>", bufopts)
  vim.keymap.set("n", "<space>dD", "<cmd>Telescope diagnostics<CR>", bufopts)
end

local function disable_format(next)
  return function(client, bufnr)
    next(client, bufnr)
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
  end
end

local lspFormatting = vim.api.nvim_create_augroup("LspFormat", {})
local function format_on_save(next)
  return function(client, bufnr)
    next(client, bufnr)

    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = lspFormatting })
    vim.api.nvim_create_autocmd(
      "BufWritePre",
      { callback = vim.lsp.buf.formatting_seq_sync, group = lspFormatting, buffer = bufnr }
    )
  end
end

local lsp_configs = {
  ["sumneko_lua"] = require("lua-dev").setup({
    lspconfig = {
      on_attach = format_on_save(on_attach),
    },
  }),
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
  ["jsonls"] = {},
}

local function setup_lsp_config(opts)
  local config = {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 50,
    },
    capabilities = get_capabilities(),
  }

  return vim.tbl_extend("force", config, opts or {})
end

for provider, config in pairs(lsp_configs) do
  lsp[provider].setup(setup_lsp_config(config))
end

local null_status_ok, null_ls = pcall(require, "null-ls")
if not null_status_ok then
  return
end

null_ls.setup({
  on_attach = function(client, bufnr)
    if client.resolved_capabilities.document_formatting then
      vim.keymap.set(
        "n",
        "<space>=",
        "<cmd>lua vim.lsp.buf.formatting()<CR>",
        { buffer = bufnr, silent = true, noremap = true }
      )
    end
    if client.resolved_capabilities.document_range_formatting then
      vim.keymap.set(
        "n",
        "<space>=",
        "<cmd>lua vim.lsp.buf.formatting()<CR>",
        { buffer = bufnr, silent = true, noremap = true }
      )
    end
  end,
  flags = {
    debounce_text_changes = 50,
  },
  capabilities = get_capabilities(),
  sources = {
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.standardrb,
    null_ls.builtins.formatting.prettier.with({ extra_filetypes = { "svelte" } }),
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
