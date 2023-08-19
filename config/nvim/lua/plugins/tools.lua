return {
  -- Documentation generation
  {
    "danymat/neogen",
    opts = { snippet_engine = "luasnip" },
    -- stylua: ignore
    keys = {
      { "<Leader>ng", function() require("neogen").generate() end, silent = true, desc = "[N]eogen [G]enerate" },
    },
  },

  {
    "ckolkey/ts-node-action",
    dependencies = { "nvim-treesitter" },
    opts = {},
    keys = function()
      return {
        { "<leader>a", require("ts-node-action").node_action, { desc = "Trigger Node Action" } },
      }
    end,
  },

  -- Test runner
  -- {
  --   "nvim-neotest/neotest",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "rouge8/neotest-rust",
  --     "olimorris/neotest-rspec",
  --     "plenary.nvim",
  --   },
  --   opts = function()
  --     return {
  --       adapters = {
  --         require("neotest-rspec")({
  --           rspec_cmd = function()
  --             return vim.tbl_flatten({
  --               "bundle",
  --               "exec",
  --               "rspec",
  --             })
  --           end,
  --         }),
  --       },
  --     }
  --   end,
  --   -- stylua: ignore
  --   keys = {
  --     { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end },
  --     { "<leader>tt", function() require("neotest").run.run() end },
  --     { "<leader>tl", function() require("neotest").run.run_last() end },
  --     { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end },
  --     { "<leader>ta", function() require("neotest").run.attach() end },
  --     { "<leader>ti", function() require("neotest").output.open({ enter = true, last_run = true, auto_close = true }) end },
  --     { "<leader>to", function() require("neotest").output_panel.toggle() end },
  --     { "<leader>ts", function() require("neotest").summary.toggle() end },
  --     { "[n", function() require("neotest").jump.prev({ status = "failed" }) end },
  --     { "]n", function() require("neotest").jump.next({ status = "failed" }) end },
  --   },
  -- },

  {
    "vim-test/vim-test",
    --  "klen/nvim-test",
    config = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#term_position"] = "vert"
    end,
    -- stylua: ignore
    keys = {
      { "<leader>tt", "<cmd>TestNearest<CR>" },
      { "<leader>tf", "<cmd>TestFile<CR>" },
      { "<leader>ts", "<cmd>TestSuite<CR>" },
      { "<leader>tl", "<cmd>TestLast<CR>" },
      { "<leader>tg", "<cmd>TestVisit<CR>" },
    },
  },

  -- treesitter base splitjoin
  -- {
  --   "Wansmer/treesj",
  --   opts = { use_default_keymaps = false },
  --   -- stylua: ignore
  --   keys = {
  --     { "gJ", function() require("treesj").join() end },
  --     { "gS", function() require("treesj").split() end },
  --   },
  -- },

  -- Notes
  {
    "mickael-menu/zk-nvim",
    name = "zk",
    cmds = { "ZkNew", "ZkNotes", "ZkMatch", "ZkTags" },
    opts = { picker = "telescope" },
    -- stylua: ignore
    keys = {
      -- Create a new note after asking for its title.
      { "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>" },

      -- Open notes.
      { "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>" },
      -- Search for the notes matching the current visual selection.
      -- { "<leader>zo", ":'<,'>ZkMatch<CR>", {mode = "v"} },

      -- Open todos
      { "<leader>zl", "<Cmd>ZkNew { title = 'TODO', dir = 'todo' }<CR>" },

      -- Open notes associated with the selected tags.
      { "<leader>zt", "<Cmd>ZkTags<CR>" },

      { "<leader>zj", [[<Cmd>ZkNew { dir = "journal/daily" }<CR>]] },

    },
  },

  -- Alt file navigation
  {
    "ThePrimeagen/harpoon",
    -- stylua: ignore
    keys = {
      { "<leader>ha", function() require("harpoon.mark").add_file() end, { desc = "[H]arpoon [A]dd" } },
      { "<leader>hv", function() require("harpoon.ui").toggle_quick_menu() end, { desc = "[H]arpoon [V]iew" } },
      { "<M-6>", function() require("harpoon.ui").nav_file(1) end },
      { "<M-5>", function() require("harpoon.ui").nav_file(2) end },
      { "<M-4>", function() require("harpoon.ui").nav_file(3) end },
      { "<M-3>", function() require("harpoon.ui").nav_file(4) end },
      { "<M-2>", function() require("harpoon.ui").nav_file(5) end },
      { "<M-1>", function() require("harpoon.ui").nav_file(6) end },
    },
  },

  -- Navigate vim's undo tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    config = false,
    -- stylua: ignore
    keys = {
      { "<leader>ut", function() vim.cmd.UndotreeToggle() end, desc = "Open undo tree" },
    },
  },

  -- comments
  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {
      hooks = {
        pre = function()
          require("ts_context_commentstring.internal").update_commentstring({})
        end,
      },
    },
    config = function(_, opts)
      require("mini.comment").setup(opts)
    end,
  },

  -- surround
  {
    "echasnovski/mini.surround",
    keys = function(plugin, keys)
      -- Populate the keys based on the user's options
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      local mappings = {
        { opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete surrounding" },
        { opts.mappings.find, desc = "Find right surrounding" },
        { opts.mappings.find_left, desc = "Find left surrounding" },
        { opts.mappings.highlight, desc = "Highlight surrounding" },
        { opts.mappings.replace, desc = "Replace surrounding" },
        { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
      }
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        add = "gzy", -- Add surrounding in Normal and Visual modes
        delete = "gzd", -- Delete surrounding
        find = "gzf", -- Find surrounding (to the right)
        find_left = "gzF", -- Find surrounding (to the left)
        highlight = "gzh", -- Highlight surrounding
        replace = "gzs", -- Replace surrounding
        update_n_lines = "gzn", -- Update `n_lines`
      },
    },
    config = function(_, opts)
      -- use gz mappings instead of s to prevent conflict with leap
      require("mini.surround").setup(opts)
    end,
  },

  -- better text-objects
  {
    "echasnovski/mini.ai",
    keys = {
      { "a", mode = { "x", "o" } },
      { "i", mode = { "x", "o" } },
    },
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        init = function()
          -- no need to load the plugin, since we only need its queries
          require("lazy.core.loader").disable_rtp_plugin("nvim-treesitter-textobjects")
        end,
      },
    },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          b = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }, {}),
        },
      }
    end,
    config = function(_, opts)
      local ai = require("mini.ai")
      ai.setup(opts)
    end,
  },

  -- Ruby refactorings and helpers
  { "richardmarbach/extract-ruby-constant", ft = { "ruby" } },

  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "nvim-lspconfig",
      "nvim-treesitter",
    },
    config = function()
      require("go").setup()
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
}
