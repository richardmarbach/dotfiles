local M = {}

function M.setup()
  local ts = require('nvim-treesitter.configs')

  ts.setup {
    ensure_installed = 'maintained',
    highlight = { enable = true },
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
          ["]m"] = "@function.outer",
          ["]b"] = "@block.outer",
          ["]]"] = "@class.outer",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]B"] = "@block.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[B"] = "@block.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[B"] = "@block.outer",
          ["[]"] = "@class.outer",
        },
      },
    },
  }
end

return M
