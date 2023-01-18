require("config.settings")
require("config.lazy")
require("config.autocmds")
require("config.keymaps")

function R(name)
  require("plenary.reload").reload_module(name)
end
