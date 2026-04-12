local gh = require("config.gh")

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "telescope-fzf-native.nvim" and (ev.data.kind == "install" or ev.data.kind == "update") then
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    end
  end,
})

vim.pack.add({
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-telescope/telescope-file-browser.nvim"),
  gh("nvim-telescope/telescope-fzf-native.nvim"),
  gh("nvim-telescope/telescope-ui-select.nvim"),
})

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

require("telescope").setup({
  defaults = {
    mappings = {
      i = {
        ["<c-o>"] = function(...)
          require("trouble.sources.telescope").open(...)
        end,
      },
      n = {
        ["<c-o>"] = function(...)
          require("trouble.sources.telescope").open(...)
        end,
      },
    },
    extensions = {
      file_browser = {},
      ["ui-select"] = {
        require("telescope.themes").get_dropdown(),
      },
    },
  },
})

pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "file_browser")
pcall(require("telescope").load_extension, "ui-select")

-- stylua: ignore start
vim.keymap.set("n", "<leader><leader>", function() require("telescope.builtin").buffers() end, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>sp", function() require("telescope.builtin").find_files({ hidden = true }) end, { desc = "[S]earch [P]roject Files" })
vim.keymap.set("n", "<leader>sh", function() require("telescope.builtin").help_tags() end, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sr", function() require("telescope.builtin").resume() end, { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader>sw", function() require("telescope.builtin").grep_string() end, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", function() require("telescope.builtin").live_grep({ attach_mappings = attach_mappings }) end, { desc = "[S]earch by [G]rep" })
-- stylua: ignore end
vim.keymap.set("n", "<leader>sl", function()
  require("telescope.builtin").live_grep({
    hidden = true,
    cwd = require("telescope.utils").buffer_dir(),
  })
end, { desc = "[S]earch by Grep in current [L]ocation" })
-- stylua: ignore start
vim.keymap.set("n", "<leader>sd", function() require("telescope.builtin").diagnostics() end, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sb", function() require("telescope.builtin").git_branches() end, { desc = "[S]earch [B]ranches" })
vim.keymap.set("n", "<leader>sk", function() require("telescope.builtin").keymaps() end, { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>ss", function() require("telescope.builtin").builtin() end, { desc = "[S]earch Builtins" })
-- stylua: ignore end
vim.keymap.set("n", "<leader>sf", function()
  require("telescope").extensions.file_browser.file_browser({
    hidden = true,
    files = false,
  })
end, { desc = "[S]earch [F]olders" })
-- stylua: ignore start
vim.keymap.set("n", "<leader>s.", function() require("telescope.builtin").oldfiles() end, { desc = '[S]earch Recent Files ("." for repeat)' })
-- stylua: ignore end
vim.keymap.set("n", "<leader>/", function()
  require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
    winblend = 10,
    previewer = false,
  }))
end, { desc = "[/] Fuzzily search in current buffer]" })
vim.keymap.set("n", "<leader>s/", function()
  require("telescope.builtin").live_grep({
    grep_open_files = true,
    prompt_title = "Live Grep in Open Files",
  })
end, { desc = "[S]earch [/] in Open Files" })
vim.keymap.set("n", "<leader>sn", function()
  require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim files" })
