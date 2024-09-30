--- @diagnostic disable: undefined-global

local textcase = require("textcase").api

local require_var = function(args)
  local text = args[1][1] or ""
  local split = vim.split(text, ".", { plain = true })

  local options = {}
  for len = 0, #split - 1 do
    table.insert(options, t(textcase.to_snake_case(table.concat(vim.list_slice(split, #split - len, #split), "_"))))
  end

  return sn(nil, {
    c(1, options),
  })
end

local snippets = {
  s("func", {
    t("function "),
    i(1, ""),
    t("("),
    i(2),
    t({ ")", "\t" }),
    i(3),
    t({ "", "end" }),
    i(0),
  }),

  s("lfunc", {
    t("local function "),
    i(1, "f"),
    t("("),
    i(2),
    t({ ")", "\t" }),
    i(3),
    t({ "", "end" }),
    i(0),
  }),

  s(
    "s",
    fmt(
      [=[
      s("<>", 
        fmt([[
          <>
        ]], 
        {
          <>
        })
      ),
    ]=],
      { i(1), i(2), i(3) },
      { delimiters = "<>" }
    )
  ),

  s(
    "require",
    fmt(
      [[
    local {} = require("{}")
  ]]   ,
      { d(2, require_var, { 1 }), i(1) }
    )
  ),

  s(
    "pcall",
    fmt(
      [[
    local status_ok, {} = pcall(require, "{}")
    if not status_ok then
      return
    end
    ]] ,
      {
        d(2, require_var, { 1 }),
        i(1),
      }
    )
  ),
}

local autosnippets = {}

return snippets, autosnippets
