return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      sync_install = false,

      -- Add languages to be installed here that you want installed for treesitter
      ensure_installed = {
        "c",
        "css",
        "diff",
        "fish",
        "gitignore",
        "go",
        "graphql",
        "html",
        "http",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "nix",
        "python",
        "regex",
        "ruby",
        "rust",
        "scss",
        "sql",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "zig",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighing = "markdown",
      },
      indent = { enable = true, disable = { "python" } },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<c-space>",
          node_incremental = "<c-space>",
          scope_incremental = "<nop>",
          node_decremental = "<bs>",
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    config = true,
  },
}
