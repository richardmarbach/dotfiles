return {
  -- Documentation generation
  {
    "danymat/neogen",
    opts = { snippet_engine = "luasnip" },
    keys = {
      {
        "<Leader>ng",
        function()
          require("neogen").generate()
        end,
        silent = true,
        desc = "[N]eogen [G]enerate",
      },
    },
  },

  -- Test runner
  {
    "vim-test/vim-test",
    --  "klen/nvim-test",
    config = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#term_position"] = "vert"
    end,
    keys = {
      { "<leader>tt", "<cmd>TestNearest<CR>" },
      { "<leader>tf", "<cmd>TestFile<CR>" },
      { "<leader>ts", "<cmd>TestSuite<CR>" },
      { "<leader>tl", "<cmd>TestLast<CR>" },
      { "<leader>tg", "<cmd>TestVisit<CR>" },
    },
  },

  -- treesitter base splitjoin
  {
    "Wansmer/treesj",
    opts = { use_default_keymaps = false },
    keys = {
      {
        "gJ",
        function()
          require("treesj").join()
        end,
      },
      {
        "gS",
        function()
          require("treesj").split()
        end,
      },
    },
  },

  -- Notes
  {
    "mickael-menu/zk-nvim",
    name = "zk",
    cmds = { "ZkNew", "ZkNotes", "ZkMatch", "ZkTags" },
    opts = { picker = "telescope" },
    keys = {
      -- Create a new note after asking for its title.
      { "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>" },

      -- Open notes.
      { "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>" },
      -- Open notes associated with the selected tags.
      { "<leader>zt", "<Cmd>ZkTags<CR>" },

      { "<leader>zj", [[<Cmd>ZkNew { dir = "$ZK_NOTEBOOK_DIR/journal" }<CR>]] },

      -- Search for the notes matching a given query.
      { "<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>" },
      -- Search for the notes matching the current visual selection.
      { "<leader>zf", ":'<,'>ZkMatch<CR>" },
    },
  },

  -- Alt file navigation
  {
    "ThePrimeagen/harpoon",
    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon.mark").add_file()
        end,
        { desc = "[H]arpoon [A]dd" },
      },
      {
        "<leader>hv",
        function()
          require("harpoon.ui").toggle_quick_menu()
        end,
        { desc = "[H]arpoon [V]iew" },
      },

      {
        "<C-6>",
        function()
          require("harpoon.ui").nav_file(1)
        end,
      },
      {
        "<C-5>",
        function()
          require("harpoon.ui").nav_file(2)
        end,
      },
      {
        "<C-4>",
        function()
          require("harpoon.ui").nav_file(3)
        end,
      },
      {
        "<C-3>",
        function()
          require("harpoon.ui").nav_file(4)
        end,
      },
      {
        "<C-2>",
        function()
          require("harpoon.ui").nav_file(5)
        end,
      },
      {
        "<C-1>",
        function()
          require("harpoon.ui").nav_file(6)
        end,
      },
    },
  },

  -- Navigate vim's undo tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    config = false,
    keys = {
      {
        "<leader>u",
        function()
          vim.cmd.UndotreeToggle()
        end,
        desc = "Open undo tree",
      },
    },
  },
}
