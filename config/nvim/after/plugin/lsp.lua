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

local neodev_status_ok, neodev = pcall(require, "neodev")
if not neodev_status_ok then
  return
end
neodev.setup({})

local status_ok, lsp = pcall(require, "lspconfig")
if not status_ok then
  return
end

local saga_status_ok, lspsaga = pcall(require, "lspsaga")
if not saga_status_ok then
  return
end

lspsaga.init_lsp_saga({
  code_action_lightbulb = {
    virtual_text = false,
  },
  finder_request_timeout = 10000,
})

local keymap = vim.keymap.set

local function get_capabilities()
  return require("cmp_nvim_lsp").default_capabilities()
end

local function on_attach(_, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  local bufopts = { buffer = bufnr, noremap = true, silent = true }
  keymap("n", "K", "<Cmd>Lspsaga hover_doc<cr>", bufopts)
  keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", bufopts)
  keymap("i", "<C-g>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", bufopts)
  keymap("n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", bufopts)
  keymap("n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", bufopts)
  keymap("n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", bufopts)
  keymap("n", "<space>rn", "<cmd>Lspsaga rename<CR>", bufopts)
  keymap({ "n", "v" }, "<space>ca", "<cmd>Lspsaga code_action<cr>", bufopts)
  keymap("n", "<C-]>", "<cmd>lua vim.lsp.buf.definition()<CR>", bufopts)
  keymap("n", "gd", "<cmd>Lspsaga peek_definition<CR>", bufopts)
  keymap("n", "gr", "<cmd>Lspsaga lsp_finder<CR>", bufopts)
  keymap("n", "<space>e", "<cmd>Lspsaga show_cursor_diagnostic<CR>", bufopts)
  keymap("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<cr>", bufopts)
  keymap("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<cr>", bufopts)
  keymap("n", "[E", function()
    require("lspsaga.diagnostic").goto_prev({ severity = vim.diagnostic.severity.ERROR })
  end, { silent = true })
  keymap("n", "]E", function()
    require("lspsaga.diagnostic").goto_next({ severity = vim.diagnostic.severity.ERROR })
  end, { silent = true })
  keymap("n", "<space>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", bufopts)
  keymap("n", "<space>dd", "<cmd>Telescope diagnostics bufnr=0<CR>", bufopts)
  keymap("n", "<space>dD", "<cmd>Telescope diagnostics<CR>", bufopts)
end

local function disable_format(next)
  return function(client, bufnr)
    next(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end
end

local lspFormatting = vim.api.nvim_create_augroup("LspFormat", {})
local function format_on_save(next)
  return function(client, bufnr)
    next(client, bufnr)

    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = lspFormatting })
    vim.api.nvim_create_autocmd("BufWritePre", {
      callback = function()
        vim.lsp.buf.format()
      end,
      group = lspFormatting,
      buffer = bufnr,
    })
  end
end

local lsp_configs = {
  ["sumneko_lua"] = {
    on_attach = format_on_save(on_attach),
  },
  ["tailwindcss"] = {
    settings = {
      tailwindCSS = {
        experimental = {
          classRegex = { -- for haml :D
            "%\\w+([^\\s]*)",
            "\\.([^\\.]*)",
            ':class\\s*=>\\s*"([^"]*)',
            'class:\\s+"([^"]*)',
          },
        },
      },
    },
  },
  ["solargraph"] = {
    on_attach = disable_format(on_attach),
    init_options = {
      formatting = false,
    },
    settings = {
      solargraph = {
        diagnostics = true,
        useBundler = true,
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
    if client.server_capabilities.documentFormattingProvider then
      keymap(
        "n",
        "<space>=",
        "<cmd>lua vim.lsp.buf.format { async = true }<CR>",
        { buffer = bufnr, silent = true, noremap = true }
      )
    end
    if client.server_capabilities.documentRangeFormattingProvider then
      keymap(
        "n",
        "<space>=",
        "<cmd>lua vim.lsp.buf.format { async = true }<CR>",
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
    null_ls.builtins.formatting.standardrb.with({
      prefer_local = "bin",
    }),
    null_ls.builtins.formatting.prettier.with({ extra_filetypes = { "svelte" } }),
    null_ls.builtins.diagnostics.eslint.with({ extra_filetypes = { "svelte" } }),
    null_ls.builtins.code_actions.eslint.with({ extra_filetypes = { "svelte" } }),
    null_ls.builtins.code_actions.gitsigns,
    null_ls.builtins.completion.spell,

    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.formatting.shellharden,
    null_ls.builtins.formatting.shfmt,
    null_ls.builtins.formatting.xmllint,

    null_ls.builtins.formatting.pg_format,
  },
})
