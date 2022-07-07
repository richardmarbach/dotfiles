local textcase = require("textcase").api

return {
  s("cla", {
    t("class "),
    i(1, textcase.to_pascal_case(vim.fn.expand("%:t:r"))),
    t({ "", "\t" }),
    i(2),
    t({ "", "end" }),
  }),
}
