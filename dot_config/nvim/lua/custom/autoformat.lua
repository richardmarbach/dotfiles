local M = {}

M.autoformat = true

function M.setup()
  vim.api.nvim_create_user_command("ToggleAutoFormat", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("AutoFormat", {}),
    callback = function(args)
      if M.autoformat and vim.bo[args.buf].buftype == "" then
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
  require("conform").format({ timeout_ms = 10000, buf = buf })
end

return M
