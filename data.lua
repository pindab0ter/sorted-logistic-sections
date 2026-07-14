data:extend({
    {
        type = "custom-input",
        name = "sorted-logistic-sections-hotkey",
        key_sequence = "",
        action = "lua",
    },
    {
        type = "shortcut",
        name = "sorted-logistic-sections-toggle",
        action = "lua",
        toggleable = true,
        associated_control_input = "sorted-logistic-sections-hotkey",
        icon = "__sorted-logistic-sections__/graphics/shortcut_32.png",
        icon_size = 32,
        small_icon = "__sorted-logistic-sections__/graphics/shortcut_24.png",
        small_icon_size = 24
    },
})
