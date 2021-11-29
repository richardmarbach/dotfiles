local M = {}

local defaultConfig = {
  formatters = {},
}
local formatter = require('formatter')

function M.setup(config)
  config = config or {}
  vim.tbl_deep_extend("force", defaultConfig, config)

  local configs = {}
  for _, name in ipairs(config.formatters) do
    local fmt = require('config.formatter.' .. name)
    for _, language in ipairs(fmt.languages) do
      if configs[language] == nil then
        configs[language] = fmt.config
      else
        print("'" .. name .. "' is attempting to redefine the formatter for '" .. language .. "' and has been ignored.")
      end
    end
  end
  formatter.setup({
    filetype = configs
  })
end

return M
