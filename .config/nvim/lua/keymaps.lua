local M = {}

local opts = {noremap = true, silent = true}

local mode_adapters = {
  insert_mode = 'i',
  normal_mode = 'n',
  term_mode = 't',
  visual_mode = 'v',
  visual_block_mode = 'x',
  command_mode = 'c',
  operator_pending_mode = 'o',
  select_mode = 's',
  ic = '!',
  ic_lang_arg_mode = 'l',
  nvso = '',
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
  normal_mode = {
    ["<leader>v"] = "<cmd>tabnew $MYVIMRC<CR>",
    ["<leader><leader>"] = "<C-^>",

    ["<leader>t"] ={"<cmd>lua require('run_tests').run_test_file()<CR>", {noremap=true, silent=false}},
    ["<leader>T"] ={"<cmd>lua require('run_tests').run_nearest_test()<CR>", {noremap=true, silent=false}},
    ["<leader>a"] ={"<cmd>lua require('run_tests').run_tests()<CR>", {noremap=true, silent=false}},

    ["<leader>n"] = "<cmd>lua require('utils.file').rename()<cr>",

    ["<space>="] = "<cmd>Format<CR>",

    ["<leader>gg"] = "<cmd>lua require('telescope.builtin').live_grep()<CR>",
    ["<leader>gw"] = "<cmd>lua require('telescope.builtin').grep_string()<CR>",
    ["<leader>ge"] = "<cmd>lua require('telescope.builtin').live_grep({cwd = require('telescope.utils').buffer_dir()})<CR>",
    ["<leader>ga"] = "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'parts/', 'app/'}})<cr>",
    ["<leader>gs"] = "<cmd>lua require('telescope.builtin').live_grep({search_dirs = {'spec/'}})<cr>",

    ["<leader>ff"] = "<cmd>lua require('telescope.builtin').find_files()<CR>",
    ["<leader>fe"] = "<cmd>lua require('telescope.builtin').find_files({cwd = require('telescope.utils').buffer_dir()})<CR>",
    ["<leader>fs"] = "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'spec/'}})<CR>",
    ["<leader>fa"] = "<cmd>lua require('telescope.builtin').find_files({search_dirs = {'parts/', 'app/'}})<CR>",

    ["<leader>fb"] = "<cmd>Telescope buffers<cr>",
    ["<leader>fc"] = "<cmd>Telescope git_commits<cr>",
    ["<leader>fd"] = "<cmd>Telescope git_bcommits<cr>",
  },
  insert_mode = {
    ["<C-l>"] = { "<space>=><space>", { noremap = true } },
  },
  command_mode = {
    ["%%"] = {"expand('%:h').'/'", { expr = true, noremap = true }},
  },
}

local lsp_keymappings = {
  normal_mode = {
    ['gD'] = '<Cmd>lua vim.lsp.buf.declaration()<CR>',
    ['gd'] = '<Cmd>Telescope lsp_definitions<CR>',
    ['K'] = '<Cmd>lua vim.lsp.buf.hover()<CR>',
    ['gi'] = '<cmd>Telescope lsp_implementations<CR>',
    ['<C-k>'] = '<cmd>lua vim.lsp.buf.signature_help()<CR>',
    ['<space>wa'] = '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>',
    ['<space>wr'] = '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>',
    ['<space>wl'] = '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
    ['<space>D'] = '<cmd>Telescope lsp_type_definitions<CR>',
    ['<space>rn'] = '<cmd>lua vim.lsp.buf.rename()<CR>',
    ['<space>ca'] = '<cmd>Telescope lsp_code_actions<CR>',
    ['gr'] = '<cmd>Telescope lsp_references<CR>',
    ['<space>e'] = '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
    ['[d'] = '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>',
    [']d'] = '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>',
    ['<space>q'] = '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>',
    ['<space>dd'] = '<cmd>Telescope lsp_document_diagnostics<CR>',
    ['<space>dD'] = '<cmd>Telescope lsp_workspace_diagnostics<CR>',
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
