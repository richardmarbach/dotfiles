--- @diagnostic disable: undefined-global

return {
  s("struct", {
    t("struct "),
    i(1, "Struct"),
    t({ " {", "\t" }),
    i(2),
    t({ "", "}" }),
  }),

  s("#derive", {
    t("#[derive("),
    i(1, "Debug"),
    t(")]"),
  }),

  s("#", {
    t("#["),
    i(1),
    t("("),
    i(2),
    t(")]"),
  }),

  s("fn", {
    t("fn "),
    i(1),
    t("("),
    i(2),
    t(")"),
    i(3),
    t({ "{", "\t" }),
    i(4),
    t({ "", "}" }),
  }),

  s("ifl", {
    t("if let "),
    i(1),
    t(" = "),
    i(2),
    t({ " {", "\t" }),
    i(3),
    t({ "", "}" }),
  }),

  s("let", {
    t("let "),
    i(1),
    t(" = "),
    i(2),
    t(";"),
  }),

  s("letm", {
    t("let mut "),
    i(1),
    t(" = "),
    i(2),
    t(";"),
  }),

  s("for", {
    t("for "),
    i(1),
    t(" in "),
    i(2),
    t({ " {", "\t" }),
    i(3),
    t({ "", "}" }),
  }),

  s("println", {
    t('println!("'),
    c(1, {
      sn(nil, { i(1, "{}") }),
      sn(nil, { i(1, "{:?}") }),
    }),
    t('", '),
    i(2),
    t(");"),
  }),

  s("match", {
    t("match "),
    i(1),
    t({ " {", "\t" }),
    i(2),
    t(" => "),
    i(3),
    t({ "", "};" }),
  }),

  s("type", {
    t("type "),
    i(1),
    t(" = "),
    i(2),
    t(";"),
  }),
}
