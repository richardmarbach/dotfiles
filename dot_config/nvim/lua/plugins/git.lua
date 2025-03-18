return {
  -- Git from vim!
  -- {
  --   "tpope/vim-fugitive",
  --   dependencies = {
  --     { "tpope/vim-rhubarb", cmd = "Browse" },
  --   },
  --   config = false,
  --   lazy = false,
  -- },
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
      on_attach = function(bufnr)
        -- local gs = package.loaded.gitsigns
        --
        -- local function map(mode, l, r, desc)
        --   vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        -- end
        --
        -- -- stylua: ignore start
        -- map("n", "]h", gs.next_hunk, "Next Hunk")
        -- map("n", "[h", gs.prev_hunk, "Prev Hunk")
        -- map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        -- map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        -- map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        -- map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        -- map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        -- map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
        -- map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        -- map("n", "<leader>ghd", gs.diffthis, "Diff This")
        -- map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        -- map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")

        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end)

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end)

        -- Actions
        map("n", "<leader>hs", gitsigns.stage_hunk)
        map("n", "<leader>hr", gitsigns.reset_hunk)

        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end)

        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end)

        map("n", "<leader>hS", gitsigns.stage_buffer)
        map("n", "<leader>hR", gitsigns.reset_buffer)
        map("n", "<leader>hp", gitsigns.preview_hunk)
        map("n", "<leader>hi", gitsigns.preview_hunk_inline)

        map("n", "<leader>hb", function()
          gitsigns.blame_line({ full = true })
        end)

        map("n", "<leader>hd", gitsigns.diffthis)

        map("n", "<leader>hD", function()
          gitsigns.diffthis("~")
        end)

        map("n", "<leader>hQ", function()
          gitsigns.setqflist("all")
        end)
        map("n", "<leader>hq", gitsigns.setqflist)

        -- Toggles
        map("n", "<leader>tb", gitsigns.toggle_current_line_blame)
        map("n", "<leader>td", gitsigns.toggle_deleted)
        map("n", "<leader>tw", gitsigns.toggle_word_diff)

        -- Text object
        map({ "o", "x" }, "ih", gitsigns.select_hunk)
      end,
    },
  },
}
