return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    config = function()
      require("nvim-treesitter").setup({
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
      })

      -- Disable treesitter indent for python
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          vim.bo.indentexpr = ""
        end,
      })

      -- Incremental selection keymaps
      vim.keymap.set("n", "<C-Space>", function()
        require("nvim-treesitter.incremental_selection").init_selection()
      end, { desc = "Init treesitter selection" })
      vim.keymap.set("x", "<C-Space>", function()
        require("nvim-treesitter.incremental_selection").node_incremental()
      end, { desc = "Increment treesitter selection" })
      vim.keymap.set("x", "<BS>", function()
        require("nvim-treesitter.incremental_selection").node_decremental()
      end, { desc = "Decrement treesitter selection" })

      -- Only apply special highlighting for mise files
      vim.treesitter.query.add_predicate("is-mise?", function(_, _, bufnr, _)
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

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        move = {
          set_jumps = true,
        },
      })

      local move = require("nvim-treesitter-textobjects.move")
      local modes = { "n", "x", "o" }

      -- goto_next_start
      vim.keymap.set(modes, "]b", function()
        move.goto_next_start("@block.outer", "textobjects")
      end, { desc = "Next block start" })
      vim.keymap.set(modes, "]m", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function start" })
      vim.keymap.set(modes, "][", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class start" })
      vim.keymap.set(modes, "]o", function()
        move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
      end, { desc = "Next loop" })
      vim.keymap.set(modes, "]s", function()
        move.goto_next_start("@local.scope", "locals")
      end, { desc = "Next scope" })
      vim.keymap.set(modes, "]z", function()
        move.goto_next_start("@fold", "folds")
      end, { desc = "Next fold" })

      -- goto_next_end
      vim.keymap.set(modes, "]B", function()
        move.goto_next_end("@block.outer", "textobjects")
      end, { desc = "Next block end" })
      vim.keymap.set(modes, "]M", function()
        move.goto_next_end("@function.outer", "textobjects")
      end, { desc = "Next function end" })
      vim.keymap.set(modes, "]O", function()
        move.goto_next_end({ "@loop.inner", "@loop.outer" }, "textobjects")
      end, { desc = "Next loop end" })
      vim.keymap.set(modes, "]S", function()
        move.goto_next_end("@local.scope", "locals")
      end, { desc = "Next scope end" })
      vim.keymap.set(modes, "]Z", function()
        move.goto_next_end("@fold", "folds")
      end, { desc = "Next fold end" })

      -- goto_previous_start
      vim.keymap.set(modes, "[b", function()
        move.goto_previous_start("@block.outer", "textobjects")
      end, { desc = "Previous block start" })
      vim.keymap.set(modes, "[m", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous function start" })
      vim.keymap.set(modes, "[[", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class start" })
      vim.keymap.set(modes, "[o", function()
        move.goto_previous_start({ "@loop.inner", "@loop.outer" }, "textobjects")
      end, { desc = "Previous loop" })
      vim.keymap.set(modes, "[s", function()
        move.goto_previous_start("@local.scope", "locals")
      end, { desc = "Previous scope" })
      vim.keymap.set(modes, "[z", function()
        move.goto_previous_start("@fold", "folds")
      end, { desc = "Previous fold" })

      -- goto_previous_end
      vim.keymap.set(modes, "[B", function()
        move.goto_previous_end("@block.outer", "textobjects")
      end, { desc = "Previous block end" })
      vim.keymap.set(modes, "[M", function()
        move.goto_previous_end("@function.outer", "textobjects")
      end, { desc = "Previous function end" })
      vim.keymap.set(modes, "[O", function()
        move.goto_previous_end({ "@loop.inner", "@loop.outer" }, "textobjects")
      end, { desc = "Previous loop end" })
      vim.keymap.set(modes, "[S", function()
        move.goto_previous_end("@local.scope", "locals")
      end, { desc = "Previous scope end" })
      vim.keymap.set(modes, "[Z", function()
        move.goto_previous_end("@fold", "folds")
      end, { desc = "Previous fold end" })
    end,
  },
}
