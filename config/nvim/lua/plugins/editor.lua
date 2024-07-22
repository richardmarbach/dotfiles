return {
  -- Detect tabstop and shiftwidth automatically
  { "NMAC427/guess-indent.nvim", event = "VeryLazy", opts = {} },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-file-browser.nvim",
      -- Fuzzy Finder Algorithm which dependencies local dependencies to be built. Only load if `make` is available
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 },
      { "nvim-telescope/telescope-ui-select.nvim" },
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
    -- stylua: ignore
    keys = {
      { "<leader><leader>", function() require("telescope.builtin").buffers() end, { desc = "[ ] Find existing buffers" } },
      { "<leader>sp", function() require("telescope.builtin").find_files({ hidden = true }) end, { desc = "[S]earch [P]roject Files" } },
      { "<leader>sh", function() require("telescope.builtin").help_tags() end, { desc = "[S]earch [H]elp" } },
      { "<leader>sr", function() require("telescope.builtin").resume() end, { desc = "[S]earch [R]esume" } },
      { "<leader>sw", function() require("telescope.builtin").grep_string() end, { desc = "[S]earch current [W]ord" } },
      { "<leader>sg", function() require("telescope.builtin").live_grep() end, { desc = "[S]earch by [G]rep" } },
      { "<leader>sl", function() require("telescope.builtin").live_grep({
        hidden = true,
        cwd = require("telescope.utils").buffer_dir()
      }) end, { desc = "[S]earch by Grep in current [L]ocation" } },
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, { desc = "[S]earch [D]iagnostics" } },
      { "<leader>sb", function() require("telescope.builtin").git_branches() end, { desc = "[S]earch [B]ranches" } },
      { '<leader>sk', function() require("telescope.builtin").keymaps() end, { desc = '[S]earch [K]eymaps' }},
      { '<leader>ss', function() require("telescope.builtin").builtin() end, { desc = '[S]earch [K]eymaps' }},
      { "<leader>sf", function() require("telescope").extensions.file_browser.file_browser({
        hidden = true, files = false
      }) end, { desc = "[S]earch [F]olders" } },
      -- { "<leader>se", function() require("telescope").extensions.file_browser.file_browser({
      --   hidden = true,
      --   cwd = require("telescope.utils").buffer_dir(),
      -- }) end, { desc = "Browse files in current folder" } },
      { '<leader>s.', function() require("telescope.builtin").oldfiles() end, { desc = '[S]earch Recent Files ("." for repeat)' }},
      { "<leader>/", function()
          -- You can pass additional configuration to telescope to change theme, layout, etc.
          require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
          }))
        end, { desc = "[/] Fuzzily search in current buffer]" },
      },
      { '<leader>s/',
        function()
          require("telescope.builtin").live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        { desc = '[S]earch [/] in Open Files' }
      },
      { '<leader>sn',
        function()
          require("telescope.builtin").find_files { cwd = vim.fn.stdpath 'config' }
        end,
        { desc = '[S]earch [N]eovim files' }
      }
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
  },

  -- Git from vim!
  {
    "tpope/vim-fugitive",
    dependencies = {
      { "tpope/vim-rhubarb", cmd = "Browse" },
    },
    config = false,
    lazy = false,
  },

  {
    "sindrets/diffview.nvim",
    -- Don't lazy load so that we call it on startup for e.g. mergetool
    lazy = false,
    dependencies = { "plenary.nvim" },
    keys = {
      { "<leader>hf", "<cmd>DiffviewFileHistory %<cr>", { desc = "Git history for current file" } },
      { "<leader>ho", "<cmd>DiffviewOpen<cr>", { desc = "Open Diffview" } },
      { "<leader>hc", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
    },
    opts = {
      enhanced_diff_hl = true,
    },
  },

  -- Git gutter
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]h", gs.next_hunk, "Next Hunk")
        map("n", "[h", gs.prev_hunk, "Prev Hunk")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
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
