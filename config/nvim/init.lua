require("rm.settings")

require("rm.plugins")

require("rm.colorscheme")

local is_mac = vim.fn.has("macunix") == 1

if is_mac then
  require("rm.macos")
end
