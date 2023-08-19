local M = {}

M.autoformat = true

function M.setup()
  vim.api.nvim_create_user_command("ToggleAutoFormat", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("AutoFormat", {}),
    callback = function()
      if M.autoformat then
        M.format()
      end
    end,
  })
end

function M.toggle()
  M.autoformat = not M.autoformat
end

function M.format()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local have_formatter = #require("formatter.config").formatters_for_filetype(ft) > 0

  if have_formatter then
    vim.cmd([[Format]])
  else
    vim.lsp.buf.format({
      bufnr = buf,
      timeout_ms = 5000,
    })
  end
end

return M
