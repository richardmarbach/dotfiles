local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

telescope.setup({
  defaults = {
    layout_strategy = "bottom_pane",
  },
  extensions = {
    fzf = {
      override_generic_sorter = false,
      override_file_sorter = true,
    },
  },
})

telescope.load_extension("fzf")
telescope.load_extension("file_browser")
