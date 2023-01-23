return {
  {
    "VonHeikemen/lsp-zero.nvim",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },

      -- CLI tool (such as formatters) integration
      "jose-elias-alvarez/null-ls.nvim",
      "jay-babu/mason-null-ls.nvim",

      -- Autocompletion
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "saadparwaiz1/cmp_luasnip" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "richardmarbach/cmp-via" },

      -- Snippets
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" },


      -- Additional lua configuration, makes nvim stuff amazing
      "folke/neodev.nvim",
    },
  },

  -- Rust
  "simrat39/rust-tools.nvim",

  -- { "numToStr/Comment.nvim", config = true }, -- "gc" to comment visual regions/lines
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

  -- { "kylechui/nvim-surround", config = true }, -- Surround text objects

  -- Text casing library
  "johmsalas/text-case.nvim",

  -- Ruby refactorings and helpers
  { "richardmarbach/extract-ruby-constant", ft = { "ruby" } },

  -- library used by other plugins
  { "nvim-lua/plenary.nvim", lazy = true },
}
