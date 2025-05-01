local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = {
    color = colors.white,
    padding_left = 0,
    padding_right = 17,
    font = {
      style = settings.font.style_map["Semibold"],
      size = 13.0,
    },
  },
  label = {
    color = colors.white,
    padding_left = 0,
    padding_right = 0,
    width = 49,
    align = "right",
    font = {
      style = settings.font.style_map["Semibold"],
      size = 13.0,
    },
  },
  position = "right",
  update_freq = 30,
  padding_left = 10,
  padding_right = 10,
  click_script = "open -a 'Calendar'"
})

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  -- Construct date text (e.g. "Wed Jan 1")
  local date_text = os.date("%a %b ") .. os.date("%e"):gsub("^%s+", "")
  -- Construct time text (e.g. "1:45 PM")
  local time_text = os.date("%I:%M %p"):gsub("^0", "")

  cal:set({ icon = date_text, label = time_text })
end)
