--- @diagnostic disable: undefined-global

local function derive()
  return sn(nil, {
    t("#[derive("),
    i(1, "Debug"),
    t(")]"),
  })
end

return {
  s("struct", {
    c(2, {
      derive(),
      t(""),
    }),
    t({ "", "struct " }),
    i(1, "Struct"),
    t({ " {", "\t" }),
    i(3),
    t({ "", "}" }),
  }),

  s("impl", {
    t("impl "),
    i(1),
    c(2, {
      t(""),
      sn(nil, { t(" for "), i(1) }),
    }),
    t({ " {", "\t" }),
    i(3),
    t({ "", "}" }),
  }),

  s("#derive", derive()),

  s("#", {
    t("#["),
    i(1),
    t("("),
    i(2),
    t(")]"),
  }),

  s(
    "method",
    fmt(
      [[
      fn(<>, <>) <> {
        <>
      }
    ]] ,
      {
        c(1, {
          t("&self"),
          t("&mut self"),
          t("self"),
        }),
        i(2),
        i(3),
        i(4),
      },
      { delimiters = "<>" }
    )
  ),

  s("fn", {
    t("fn "),
    i(1),
    t("("),
    i(2),
    t(")"),
    i(3),
    t({ " {", "\t" }),
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

  s(
    "for",
    fmt(
      [[
      for {} in {} {{
        {}
      }}
    ]] ,
      {
        i(1, "i"),
        c(2, {
          i(nil),
          sn(nil, { r(1, "start"), t(".."), r(2, "end") }),
          sn(nil, { r(1, "start"), t("..="), r(2, "end") }),
        }),
        i(3),
      }
    )
  ),

  s("type", {
    t("type "),
    i(1),
    t(" = "),
    i(2),
    t(";"),
  }),
}
