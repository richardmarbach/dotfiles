local gh = require("config.gh")

vim.pack.add({
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("richardmarbach/extract-ruby-constant"),
})
require("nvim-web-devicons").setup({})

require("plugins.colorscheme")
require("plugins.treesitter")
require("plugins.trouble")
require("plugins.telescope")
require("plugins.lsp")
require("plugins.snippets")
require("plugins.formatting")
require("plugins.linting")
require("plugins.git")
require("plugins.gitlink")
require("plugins.comments")
require("plugins.editor")
require("plugins.fold")
require("plugins.lualine")
require("plugins.indent-blank-line")
require("plugins.tools")
require("plugins.dap")
require("plugins.test")
require("plugins.search")
require("plugins.go")
require("plugins.lazydev")
require("plugins.otter")
require("plugins.undotree")
require("plugins.text-case")
require("plugins.zk")
