local refine_files_action = function(prompt_bufnr)
  require("telescope.actions.generate").refine(prompt_bufnr, {
    prompt_title = "Refine search results",
  })
end

local attach_mappings = function(_, map)
  map("i", "<c-space>", refine_files_action)
  map("n", "<c-space>", refine_files_action)
  map("i", "<c-f>", require("telescope.actions").to_fuzzy_refine)
  return true
end

return {
  -- Detect tabstop and shiftwidth automatically
  { "NMAC427/guess-indent.nvim", event = "VeryLazy", opts = {} },

  {
    dir = "~/projects/telescope.nvim",
    -- "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-file-browser.nvim",
      -- Fuzzy Finder Algorithm which dependencies local dependencies to be built. Only load if `make` is available
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },
      { "nvim-telescope/telescope-ui-select.nvim" },
      -- { dir = "~/projects/telescope-refined-live-grep.nvim" },
    },
    config = function()
      local trouble = require("trouble.sources.telescope")

      require("telescope").setup({
        defaults = {
          mappings = {
            i = { ["<c-o>"] = trouble.open_with_trouble },
            n = { ["<c-o>"] = trouble.open_with_trouble },
          },
          extensions = {
            file_browser = {
              -- hijack_netrw = true,
            },
            ["ui-select"] = {
              require("telescope.themes").get_dropdown(),
            },
          },
        },
      })

      -- Enable telescope fzf native, if installed
      pcall(require("telescope").load_extension, "fzf")

      -- Enable filebrowser
      pcall(require("telescope").load_extension, "file_browser")
      pcall(require("telescope").load_extension, "ui-select")
    end,
    cmd = { "Telescope" },
    keys = {
      -- stylua: ignore
      { "<leader><leader>", function() require("telescope.builtin").buffers() end, { desc = "[ ] Find existing buffers" } },
      -- stylua: ignore
      { "<leader>sp", function() require("telescope.builtin").find_files({ hidden = true }) end, { desc = "[S]earch [P]roject Files" } },
      -- stylua: ignore
      { "<leader>sh", function() require("telescope.builtin").help_tags() end, { desc = "[S]earch [H]elp" } },
      -- stylua: ignore
      { "<leader>sr", function() require("telescope.builtin").resume() end, { desc = "[S]earch [R]esume" } },
      -- stylua: ignore
      { "<leader>sw", function() require("telescope.builtin").grep_string() end, { desc = "[S]earch current [W]ord" } },
      -- stylua: ignore
      { "<leader>sg", function() require("telescope.builtin").live_grep({ attach_mappings = attach_mappings }) end, { desc = "[S]earch by [G]rep" } },
      {
        "<leader>sl",
        function()
          require("telescope.builtin").live_grep({
            hidden = true,
            cwd = require("telescope.utils").buffer_dir(),
          })
        end,
        { desc = "[S]earch by Grep in current [L]ocation" },
      },
      -- stylua: ignore
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, { desc = "[S]earch [D]iagnostics" } },
      -- stylua: ignore
      { "<leader>sb", function() require("telescope.builtin").git_branches() end, { desc = "[S]earch [B]ranches" } },
      -- stylua: ignore
      { '<leader>sk', function() require("telescope.builtin").keymaps() end, { desc = '[S]earch [K]eymaps' }},
      -- stylua: ignore
      { '<leader>ss', function() require("telescope.builtin").builtin() end, { desc = '[S]earch Builtins' }},
      -- stylua: ignore
      { "<leader>sf", function() require("telescope").extensions.file_browser.file_browser({
        hidden = true, files = false
      }) end, { desc = "[S]earch [F]olders" } },
      -- stylua: ignore
      { '<leader>s.', function() require("telescope.builtin").oldfiles() end, { desc = '[S]earch Recent Files ("." for repeat)' }},
      {
        "<leader>/",
        function()
          -- You can pass additional configuration to telescope to change theme, layout, etc.
          require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
          }))
        end,
        { desc = "[/] Fuzzily search in current buffer]" },
      },
      {
        "<leader>s/",
        function()
          require("telescope.builtin").live_grep({
            grep_open_files = true,
            prompt_title = "Live Grep in Open Files",
          })
        end,
        { desc = "[S]earch [/] in Open Files" },
      },
      {
        "<leader>sn",
        function()
          require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
        end,
        { desc = "[S]earch [N]eovim files" },
      },
    },
  },

  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    keys = {
      { "<leader>se", "<cmd>Oil<cr>", { desc = "Open Oil" } },
    },
    opts = {
      default_file_explorer = true,
    },
    lazy = false,
  },

  -- Tmux integration
  {
    "EvWilson/slimux.nvim",
    config = function()
      local slimux = require("slimux")
      slimux.setup({
        target_socket = slimux.get_tmux_socket(),
        target_pane = "left",
        -- target_pane = string.format("%s.0", slimux.get_tmux_window()),
      })
      vim.keymap.set(
        "v",
        "<leader>ts",
        ':lua require("slimux").send_highlighted_text()<CR>',
        { desc = "Send currently highlighted text to configured tmux pane" }
      )
      vim.keymap.set(
        "n",
        "<leader>ts",
        ':lua require("slimux").send_paragraph_text()<CR>',
        { desc = "Send paragraph under cursor to configured tmux pane" }
      )
    end,
  },
}
