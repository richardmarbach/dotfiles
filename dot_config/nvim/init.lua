require("config.settings")
require("config.lazy")
require("config.autocmds")
require("config.keymaps")
require("config.diagnostics")

function R(name)
  require("plenary.reload").reload_module(name)
end
