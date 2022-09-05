--- @diagnostic disable: undefined-global

local textcase = require("textcase").api

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
},
  {
    s("irb", { t("binding.irb") }, { type = "autosnippets" }),
  }
