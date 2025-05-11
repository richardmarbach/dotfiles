return {
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
}
