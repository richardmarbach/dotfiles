local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
  return
end

npairs.setup({})
npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
