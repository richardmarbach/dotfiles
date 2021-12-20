local M = {}

local lsp_providers = {
  'solargraph',
  'eslint',
}

function on_attach(client, bufnr)
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  local keymaps = require('keymaps')
  keymaps.setup_lsp_mappings(bufnr)


  if client.resolved_capabilities.document_formatting then
    keymaps.set_buf_keymap(bufnr, 'n', "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
--    vim.api.nvim_command[[augroup Format]]
--    vim.api.nvim_command[[autocmd! * <buffer>]]
--    vim.api.nvim_command[[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
--    vim.api.nvim_command[[augroup END]]
  end
  if client.resolved_capabilities.document_range_formatting then
    keymaps.set_buf_keymap(bufnr, 'n', "<space>=", "<cmd>lua vim.lsp.buf.formatting()<CR>")
  end
end

function get_capabilities()
  return require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
end

function setup_lsp_config(provider)
  local config = {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 50,
    },
    capabilities = get_capabilities()
  }

  local ok, lsp_config = pcall(require, "config.lsp."..provider)
  if ok then
    config = vim.tbl_extend("force", config, lsp_config)
  end
  return config
end


function M.setup()
  local lsp = require('lspconfig')

  for _, provider in ipairs(lsp_providers) do
    lsp[provider].setup(setup_lsp_config(provider))
  end
end

return M