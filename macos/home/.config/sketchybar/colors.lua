return {
  black = 0xff11111b,
  white = 0xffcdd6f4,
  red = 0xfff38ba8,
  green = 0xffa6e3a1,
  blue = 0xff89b4fa,
  yellow = 0xfff9e2af,
  orange = 0xfffab387,
  magenta = 0xffcba6f7,
  grey = 0xff9399b2,
  transparent = 0x00000000,

  bar = {
    bg = 0xf81e1e2e,
    border = 0x6045475a,
  },
  popup = {
    bg = 0xcd1e1e2e,
    border = 0x6045475a
  },
  bg1 = 0x60313244,
  bg2 = 0x6045475a,
  bg3 = 0xc09399b2,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}

