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

      textobjects = {
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]b"] = "@block.outer",
            ["]m"] = "@function.outer",
            ["]["] = { query = "@class.outer", desc = "Next class start" },

            ["]o"] = { query = { "@loop.inner", "@loop.outer" } },

            -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
            -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
            ["]s"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
            ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
          goto_next_end = {
            ["]B"] = "@block.outer",
            ["]M"] = "@function.outer",

            ["]O"] = { query = { "@loop.inner", "@loop.outer" } },
            ["]S"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
            ["]Z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
          goto_previous_start = {
            ["[b"] = "@block.outer",
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",

            ["[o"] = { query = { "@loop.inner", "@loop.outer" } },
            ["[s"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
            ["[z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
          goto_previous_end = {
            ["[B"] = "@block.outer",
            ["[M"] = "@function.outer",

            ["[O"] = { query = { "@loop.inner", "@loop.outer" } },
            ["[S"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
            ["[Z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)

      -- Only apply special highlighting for mise files
      require("vim.treesitter.query").add_predicate("is-mise?", function(_, _, bufnr, _)
        local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
        local filename = vim.fn.fnamemodify(filepath, ":t")
        return string.match(filename, ".*mise.*%.toml$") ~= nil
      end, { force = true, all = false })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    config = true,
  },

  { "nvim-treesitter/nvim-treesitter-textobjects" },
}
