local M = {}

---@type PluginLspKeys
M._keys = nil

---@return (LazyKeys|{has?:string})[]
function M.get()
  local format = require("plugins.lsp.format").format
  ---@class PluginLspKeys
  -- stylua: ignore
  M._keys = M._keys or {
    { "gd", require("telescope.builtin").lsp_definitions, desc = "Goto Definition" },
    { "gr", require("telescope.builtin").lsp_references, desc = "References" },
    { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
    { "gI", require("telescope.builtin").lsp_implementations, desc = "Goto Implementation" },
    { "<leader>D", require("telescope.builtin").lsp_type_definitions, desc = "Goto Type Definition" },

    { "K", vim.lsp.buf.hover, desc = "Hover" },
    { "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
    { "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = "signatureHelp" },

    { "<leader>cq", vim.diagnostic.setloclist, desc = "Line Diagnostics" },
    { "<leader>ce", vim.diagnostic.open_float, desc = "Line Diagnostics" },
    { "]d", M.diagnostic_goto(true), desc = "Next Diagnostic" },
    { "[d", M.diagnostic_goto(false), desc = "Prev Diagnostic" },
    { "]e", M.diagnostic_goto(true, "ERROR"), desc = "Next Error" },
    { "[e", M.diagnostic_goto(false, "ERROR"), desc = "Prev Error" },
    { "]w", M.diagnostic_goto(true, "WARNING"), desc = "Next Warning" },
    { "[w", M.diagnostic_goto(false, "WARNING"), desc = "Prev Warning" },

    { "<leader>=", format, desc = "Format Document", has = "documentFormatting" },
    { "<leader>=", format, desc = "Format Range", mode = "v", has = "documentRangeFormatting" },
    { "<F2>", vim.lsp.buf.rename, expr = true, desc = "Rename", has = "rename" },
    { "<F4>", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" }, has = "codeAction" },
  }
  return M._keys
end

function M.on_attach(client, buffer)
  local Keys = require("lazy.core.handler.keys")
  local keymaps = {} ---@type table<string,LazyKeys|{has?:string}>

  for _, value in ipairs(M.get()) do
    local keys = Keys.parse(value)
    if keys[2] == vim.NIL or keys[2] == false then
      keymaps[keys.id] = nil
    else
      keymaps[keys.id] = keys
    end
  end

  for _, keys in pairs(keymaps) do
    if not keys.has or client.server_capabilities[keys.has .. "Provider"] then
      local opts = Keys.opts(keys)
      ---@diagnostic disable-next-line: no-unknown
      opts.has = nil
      opts.silent = true
      opts.buffer = buffer
      vim.keymap.set(keys.mode or "n", keys[1], keys[2], opts)
    end
  end
end

function M.diagnostic_goto(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

return M
