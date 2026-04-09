local gh = require("config.gh")

vim.pack.add({
  gh("ckolkey/ts-node-action"),
  gh("echasnovski/mini.surround"),
  gh("echasnovski/mini.ai"),
})

require("ts-node-action").setup({})
vim.keymap.set("n", "<leader>a", require("ts-node-action").node_action, { desc = "Trigger Node Action" })

-- surround (use gz mappings to prevent conflict with leap)
require("mini.surround").setup({
  mappings = {
    add = "gzy",
    delete = "gzd",
    find = "gzf",
    find_left = "gzF",
    highlight = "gzh",
    replace = "gzr",
    update_n_lines = "gzn",
  },
})

-- better text-objects
local ai = require("mini.ai")
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }, {}),
    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
    b = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }, {}),

    ["|"] = ai.gen_spec.pair("|", "|", { type = "non-balanced" }),
  },
})
