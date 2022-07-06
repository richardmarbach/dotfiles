local shebang = vim.regex("^#!.*/bin/\\%(env\\s\\+\\)\\?fish\\>\\C")
local function select_fish()
  if shebang:match_line(0, 0) then
    vim.bo.filetype = "fish"
  end
end
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, { pattern = { "*" }, callback = select_fish })
