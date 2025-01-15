local function get_date()
  return os.date("%Y-%m-%d")
end

return {}, {
  s("##now", { t("## " .. get_date()) }, { type = "autosnippets" }),
}
