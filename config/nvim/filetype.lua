local ft = vim.filetype

ft.add({
  extension = {
    sass = "sass",
  },
})

local shebang = vim.regex("^#!.*/bin/\\%(env\\s\\+\\)\\?fish\\>\\C")
local function select_fish()
  if shebang:match_line(0, 0) then
    vim.bo.filetype = "fish"
  end
end
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, { pattern = { "*" }, callback = select_fish })
ft.add({
  extension = {
    fish = "fish",
  },
})

ft.add({
  extension = {
    rbi = "ruby",
  },
})
