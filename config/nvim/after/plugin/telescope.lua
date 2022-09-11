local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

telescope.setup({
  defaults = {
    layout_strategy = "bottom_pane",
  },
  extensions = {
    fzf = {
      override_generic_sorter = false,
      override_file_sorter = true,
    },
  },
})

telescope.load_extension("fzf")
telescope.load_extension("file_browser")

local keymap = vim.keymap
local builtin = require("telescope.builtin")
local utils = require("telescope.utils")

keymap.set("n", "<leader>gg", function()
  builtin.live_grep()
end, { silent = true })
keymap.set("n", "<leader>gw", function()
  builtin.grep_string()
end, { silent = true })
keymap.set("n", "<leader>ge", function()
  builtin.live_grep({ cwd = utils.buffer_dir() })
end, { silent = true })
keymap.set("n", "<leader>ga", function()
  builtin.live_grep({ search_dirs = { "parts/", "app/", "lib/", "src/" } })
end, { silent = true })
keymap.set("n", "<leader>gs", function()
  builtin.live_grep({ search_dirs = { "spec/", "test/" } })
end, { silent = true })
keymap.set("n", "<leader>gc", function()
  builtin.live_grep({ search_dirs = { "config/" } })
end, { silent = true })
keymap.set("n", "<leader>gd", function()
  builtin.live_grep({ search_dirs = { vim.fn.input("Enter the directory to search: ", "", "file") } })
end, { silent = true })

keymap.set("n", "<leader>ff", function()
  builtin.find_files({ hidden = true })
end, { silent = true })
keymap.set("n", "<leader>fe", function()
  builtin.find_files({ cwd = utils.buffer_dir(), follow = true })
end, { silent = true })
keymap.set("n", "<leader>fs", function()
  builtin.find_files({ search_dirs = { "spec/", "test/" } })
end, { silent = true })
keymap.set("n", "<leader>fa", function()
  builtin.find_files({ search_dirs = { "parts/", "app/", "lib/", "src/" } })
end, { silent = true })
keymap.set("n", "<leader>fb", function()
  builtin.buffers()
end, { silent = true })
keymap.set("n", "<leader>fc", function()
  builtin.git_commits()
end, { silent = true })
keymap.set("n", "<leader>fh", function()
  builtin.help_tags()
end, { silent = true })
keymap.set("n", "<leader>fd", function()
  builtin.git_bcommits()
end, { silent = true })
keymap.set("n", "<leader>fr", function()
  builtin.resume()
end, { silent = true })

keymap.set("n", "<leader>bb", function()
  telescope.extensions.file_browser.file_browser({ hidden = true })
end, { silent = true })
keymap.set("n", "<leader>be", function()
  telescope.extensions.file_browser.file_browser({ hidden = true, cwd = utils.buffer_dir() })
end, { silent = true })
