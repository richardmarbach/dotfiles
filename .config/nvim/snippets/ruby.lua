--- @diagnostic disable: unused-local
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
--- @diagnostic enable: unused-local

local ts_locals = require("nvim-treesitter.locals")
local ts_utils = require("nvim-treesitter.ts_utils")
local textcase = require("textcase").api

local function instance_variables(_)
  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node or cursor_node:type() ~= "method_parameters" then
    return
  end
  print("called")
  print(vim.inspect(cursor_node:type()))
end

local function assign_instance_variable(args)
  local params = args[1][1]
  instance_variables(params)
  return sn(nil, fmt("@{} = {}", { i(1, params), i(2, params) }))
end

local function definit_snippet()
  return s(
    "definit",
    fmta(
      [[
      def initialize(<params>)
        <finish>
      end
      ]],
      {
        params = i(1),
        finish = i(0),
      }
    )
  )
  -- return s(
  --   "definit",
  --   fmta(
  --     [[
  --     def initialize(<params>)
  --       <assign_instance_vars><finish>
  --     end
  --     ]],
  --     {
  --       params = i(1),
  --       assign_instance_vars = d(2, assign_instance_variable, { 1 }),
  --       finish = i(0),
  --     }
  --   )
  -- )
end

local function get_current_class(position)
  return d(position, function()
    return sn(nil, i(1, textcase.to_pascal_case(vim.fn.expand("%:t:r"))))
  end, {})
end

local function block(position)
  return sn(position, { t({ "do", "\t" }), i(1), t({ "", "end" }) })
end

local function inline_block(position)
  return sn(position, { t("{ "), i(1), t(" }") })
end

local function choice_block(position)
  return c(position, {
    inline_block(position),
    block(position),
  })
end

local function inverted_choice_block(position)
  return c(position, {
    block(position),
    inline_block(position),
  })
end

local function quoted_string(position)
  return sn(position, {
    t('"'),
    i(1),
    t('"'),
  })
end

local function when_else_choice()
  return sn(
    nil,
    c(1, {
      t(""),
      sn(nil, { t({ "", "when " }), i(1, "true"), t({ "", "\t" }), i(2), d(3, when_else_choice, {}) }),
      sn(nil, { t({ "", "else", "\t" }), i(1) }),
    })
  )
end

return {
  s("mod", {
    t("module "),
    get_current_class(1),
    t({ "", "\t" }),
    i(2),
    t({ "", "end" }),
    i(0),
  }),

  s("cla", {
    t("class "),
    get_current_class(1),
    t({ "", "\t" }),
    i(2),
    t({ "", "end" }),
    i(0),
  }),

  -- s("do", {
  --   t("do"),
  --   c(1, {
  --     sn(nil, {
  --       t({ "", "\t" }),
  --       r(1, "body"),
  --     }),
  --     sn(nil, { t(" |"), i(1), t("|"), t({ "", "\t" }), r(2, "body") }),
  --   }),
  --   t({ "", "end" }),
  -- }),

  s("def", {
    t("def "),
    c(1, {
      sn(nil, { r(1, "method", i(1, "method")) }),
      sn(nil, { r(1, "method", i(1, "method")), t("("), i(2), t(")") }),
    }),
    t({ "", "\t" }),
    i(2),
    t({ "", "end" }),
    i(0),
  }),

  definit_snippet(),

  s("let", {
    t("let(:"),
    i(1),
    t(") "),
    choice_block(2),
    i(0),
  }),

  s("let!", {
    t("let!(:"),
    i(1),
    t(") "),
    choice_block(2),
    i(0),
  }),

  s(
    "if",
    fmt(
      [[
    if {}
      {}
    end
    ]],
      { i(1, false), i(2) }
    )
  ),

  s("subj", {
    t("subject"),
    c(1, {
      t(""),
      sn(nil, { t("(:"), i(1, "subject"), t(")") }),
    }),
    t(" "),
    choice_block(2),
    i(0),
  }),

  s("desc", {
    t('describe "'),
    i(1),
    t('" '),
    block(2),
    i(0),
  }),

  s("cont", {
    t('context "'),
    i(1),
    t('" '),
    block(2),
    i(0),
  }),

  s("it", {
    t("it "),
    c(1, {
      sn(nil, { quoted_string(1), t(" "), inverted_choice_block(2) }),
      sn(nil, { choice_block(1) }),
    }),
  }),

  s("before", {
    t("before "),
    inverted_choice_block(1),
  }),

  s("case", {
    t("case "),
    i(1, "type"),
    d(2, when_else_choice, {}),
    t({ "", "end" }),
    i(0),
  }),

  s("when", {
    t("when "),
    i(1, "true"),
    t({ "", "\t" }),
    i(2),
    d(3, when_else_choice, {}),
  }),

  s("priv", { t({ "private", "", "" }) }),
}, {
  s("irb", { t("binding.irb") }, { type = "autosnippets" }),
}
