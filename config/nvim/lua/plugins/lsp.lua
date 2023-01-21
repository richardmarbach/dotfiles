local servers = {
  sumneko_lua = {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },
  solargraph = {
    force_setup = true,
    init_options = {
      formatting = false,
    },
    settings = {
      solargraph = {
        useBundler = true,
      },
    },
  },
}

local function lsp_settings()
  local sign = function(opts)
    vim.fn.sign_define(opts.name, {
      texthl = opts.name,
      text = opts.text,
      numhl = ''
    })
  end

  sign({name = 'DiagnosticSignError', text = '✘'})
  sign({name = 'DiagnosticSignWarn', text = '▲'})
  sign({name = 'DiagnosticSignHint', text = '⚑'})
  sign({name = 'DiagnosticSignInfo', text = ''})

  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = 'minimal',
      border = 'rounded',
      source = 'always',
      header = '',
      prefix = '',
    },
  })

  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    {border = 'rounded'}
  )

  vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    {border = 'rounded'}
  )

  local command = vim.api.nvim_create_user_command

  command('LspWorkspaceAdd', function()
    vim.lsp.buf.add_workspace_folder()
  end, {desc = 'Add folder to workspace'})

  command('LspWorkspaceList', function()
    vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, {desc = 'List workspace folders'})

  command('LspWorkspaceRemove', function()
    vim.lsp.buf.remove_workspace_folder()
  end, {desc = 'Remove folder from workspace'})
end

local lsp_keymaps = function()
  local nmap = function(keys, func, desc)
    if desc then
      desc = "LSP: " .. desc
    end

    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  nmap("<F2>", vim.lsp.buf.rename, "[R]e[n]ame")
  nmap("<F4>", vim.lsp.buf.code_action, "[C]ode [A]ction")

  nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
  nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
  nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
  nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
  nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

  -- See `:help K` for why this keymap
  nmap("K", vim.lsp.buf.hover, "Hover Documentation")
  nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

  -- Lesser used LSP functionality
  nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
  nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
  nmap("<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, "[W]orkspace [L]ist Folders")

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
    vim.lsp.buf.format()
  end, { desc = "Format current buffer with LSP" })
end

local on_attach = function(_, bufnr)
  local buf_command = vim.api.nvim_buf_create_user_command

  lsp_keymaps(bufnr)

  buf_command(bufnr, 'LspFormat', function()
    vim.lsp.buf.format()
  end, {desc = 'Format buffer with language server'})
end

return {
  -- -- LSP Support
  -- { "williamboman/mason.nvim" ,
  --   dependencies = {
  --     { "williamboman/mason-lspconfig.nvim" },
  --   },
  --   config = function() 
  --     require("mason").setup({})
  --     require("mason-lspconfig").setup({})
  --   end
  -- },
  -- { 
  --   "neovim/nvim-lspconfig",
  --   dependencies = {
  --     {"simrat39/rust-tools.nvim"}, 
  --     -- Additional lua configuration, makes nvim stuff amazing
  --     {"folke/neodev.nvim"},
  --   }, 
  --   config = function()
  --     lsp_settings()
  --
  --     require("neodev").setup()
  --
  --     local get_servers = require('mason-lspconfig').get_installed_servers
  --     for _, server_name in ipairs(get_servers()) do
  --       require('lspconfig')[server_name].setup({
  --         on_attach = on_attach,
  --         capabilities = require('cmp_nvim_lsp').default_capabilities(),
  --       })
  --     end
  --
  --     for _, server_name in ipairs(servers) do
  --       require('lspconfig')[server_name].setup({
  --         on_attach = on_attach,
  --         capabilities = require('cmp_nvim_lsp').default_capabilities(),
  --       })
  --     end
  --
  --   end
  -- },
  --
  -- -- CLI tool (such as formatters) integration
  -- -- "jose-elias-alvarez/null-ls.nvim",
  -- -- "jay-babu/mason-null-ls.nvim",
}
