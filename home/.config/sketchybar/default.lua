local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 14.0
    },
    color = colors.white,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    background = { image = { corner_radius = 9 } },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 13.0
    },
    color = colors.white,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    color = colors.transparent,
    height = 24,
    corner_radius = 9,
    border_width = 0,
    border_color = colors.transparent,
    image = {
      corner_radius = 9,
      border_color = colors.grey,
      border_width = 0
    }
  },
  popup = {
    background = {
      border_width = 1,
      corner_radius = 9,
      border_color = colors.popup.border,
      color = colors.popup.bg,
      shadow = { drawing = true },
    },
    blur_radius = 50,
    y_offset = 1,
  },
  padding_left = 5,
  padding_right = 5,
  scroll_texts = true,
})
