--- @diagnostic disable: undefined-global

return {
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

  s("s", {
    t('s("'),
    i(1),
    t({ '", {', "\t" }),
    i(2),
    t({ "", "}),", "" }),
    i(0),
  }),
}
