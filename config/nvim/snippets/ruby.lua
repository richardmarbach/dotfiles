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

  s("do", {
    t("do "),
    c(1, {
      t(""),
      sn(nil, { t("|"), i(1), t("|") }),
    }),
    t({ "", "\t" }),
    i(2),
    t({ "", "end" }),
    i(0),
  }),

  s("def", {
    t("def "),
    i(1, "method"),
    c(2, {
      t(""),
      sn(nil, { t("("), i(1), t(")") }),
    }),
    t({ "", "\t" }),
    i(3),
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
}, {
  s("irb", { t("binding.irb") }, { type = "autosnippets" }),
}
