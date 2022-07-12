local status_ok, ts = pcall(require, "nvim-treesitter.configs")
if not status_ok then
  return
end

ts.setup({
  ensure_installed = "all",
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = { "markdown" },
  },
  incremental_selection = { enable = true },
  context_commentstring = { enable = true },
  indent = { enable = true },
  textobjects = {
    enable = true,
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["am"] = "@method.outer",
        ["im"] = "@method.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ["<leader>a"] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>A"] = "@parameter.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@method.outer",
        ["]b"] = "@block.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@method.outer",
        ["]B"] = "@block.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@method.outer",
        ["[B"] = "@block.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@method.outer",
        ["[B"] = "@block.outer",
        ["[]"] = "@class.outer",
      },
    },
    lsp_interop = {
      enable = true,
      border = "none",
      peek_definition_code = {
        ["<leader>df"] = "@function.outer",
        ["<leader>dF"] = "@class.outer",
      },
    },
  },
})
