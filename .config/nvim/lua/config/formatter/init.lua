local M = {}

local languages = {'ruby'}

function M.setup()
  local formatter = require('formatter')

  local configs = {}
  for _, language in ipairs(languages) do
    configs[language] = require('config.formatter.' .. language)
  end
  formatter.setup({
    filetype = configs
  })
end

return M
