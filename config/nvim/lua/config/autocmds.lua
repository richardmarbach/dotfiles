-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- create directories when needed, when saving a file
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
  callback = function(event)
    local file = vim.loop.fs_realpath(event.match) or event.match

    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    local backup = vim.fn.fnamemodify(file, ":p:~:h")
    backup = backup:gsub("[/\\]", "%%")
    vim.go.backupext = backup
  end,
})

-- Enable Ctrl-R pasting in the Telescope prompt
local telescope_augroup_id = vim.api.nvim_create_augroup("telescope", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = telescope_augroup_id,
  pattern = "TelescopePrompt",
  callback = function()
    vim.keymap.set("i", "<C-R>", "<C-R>", { silent = true, buffer = true })
  end,
})
