local gh = require("config.gh")

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "go.nvim" and (ev.data.kind == "install" or ev.data.kind == "update") then
      if not ev.data.active then
        vim.cmd.packadd("go.nvim")
      end
      require("go.install").update_all_sync()
    end
  end,
})

vim.pack.add({
  gh("ray-x/go.nvim"),
  gh("ray-x/guihua.lua"),
})

require("go").setup()
