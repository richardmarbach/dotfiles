local lsp = require("lsp-zero")
local null_ls = require("null-ls")

lsp.preset("recommended")

lsp.set_preferences({ set_lsp_keymaps = false })

-- Setup neovim lua configuration
require("neodev").setup()

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
lsp.on_attach(function(_, bufnr)
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
end)

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
  ["rust_analyzer"] = {
    on_attach = format_on_save(on_attach),
  },
  ["tsserver"] = {
    on_attach = disable_format(on_attach),
  },
  ["jsonls"] = {},
  ["elixirls"] = {
    on_attach = format_on_save(on_attach),
  },
}

for server, config in pairs(servers) do
  lsp.configure(server, config)
end

lsp.setup_nvim_cmp({
  experimental = {
    ghost_text = true,
  },
})

local cmp = require("cmp")

cmp.setup.filetype("gitcommit", {
  sources = {
    { name = "github" },
    { name = "path" },
    { name = "nvim_lsp", keyword_length = 3 },
    { name = "buffer", keyword_length = 3 },
    { name = "luasnip", keyword_length = 2 },
  },
})
vim.keymap.set("i", "<C-x><C-o>", function()
  cmp.complete()
end, { noremap = true })

lsp.setup()

local mason_nullls = require("mason-null-ls")
mason_nullls.setup({
  automatic_installation = true,
  automatic_setup = true,
})
null_ls.setup({
  sources = {
    null_ls.builtins.completion.spell,
    null_ls.builtins.formatting.pg_format,
  },
})
mason_nullls.setup_handlers({})

require("mason-nvim-dap").setup({ automatic = true })
