local wezterm = require("wezterm")

return {
  color_scheme = "Gruvbox dark, soft (base16)",
  font = wezterm.font_with_fallback({
    { family = "Hack Nerd Font Mono" },
    "Noto Color Emoji",
  }),
  font_size = 11,
  enable_tab_bar = false,
  enable_kitty_keyboard = true,
  window_decorations = "NONE",
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
}
