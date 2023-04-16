data:extend({
  {
    type = "custom-input",
    name = "ple-trash-unrequested",
    key_sequence = "ALT + T",
  },
  {
    type = "shortcut",
    name = "ple-trash-unrequested",
    icon = { filename = "__core__/graphics/icons/mip/trash.png", size = 32, mipmap_count = 2 },
    disabled_icon = { filename = "__core__/graphics/icons/mip/trash-white.png", size = 32, mipmap_count = 2 },
    action = "lua",
    associated_control_input = "ple-trash-unrequested",
    toggleable = true,
  },
})
