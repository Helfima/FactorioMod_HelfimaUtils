local default_gui = data.raw["gui-style"].default

function default_glow(tint_value, scale_value)
    return
    {
        position = { 200, 128 },
        corner_size = 8,
        tint = tint_value,
        scale = scale_value,
        draw_type = "outer"
    }
end

gui_color =
{
    white = { 1, 1, 1 },
    white_with_alpha = { 1, 1, 1, 0.5 },
    grey = { 0.5, 0.5, 0.5 },
    green = { 0, 1, 0 },
    red = { 255, 142, 142 },
    orange = { 0.98, 0.66, 0.22 },
    light_orange = { 1, 0.74, 0.40 },
    caption = { 255, 230, 192 },
    achievement_green = { 210, 253, 145 },
    achievement_tan = { 255, 230, 192 },
    achievement_failed = { 176, 171, 171 },
    achievement_failed_body = { 255, 136, 136 },
    blue = { 128, 206, 240 }
}
default_glow_color = { 225, 177, 106, 255 }
default_shadow_color = { 0, 0, 0, 0.35 }
default_dirt_color = {15, 7, 3, 100}
default_shadow = default_glow(default_shadow_color, 0.5)
default_dirt = default_glow(default_dirt_color, 0.5)

gui_graphical_set = {
    brown1 = {
        base = { position = { 370, 0 }, corner_size = 8 },
        shadow = default_shadow
    }
    ,
    brown2 = {
        base = { position = { 387, 0 }, corner_size = 8 },
        shadow = default_shadow
    }
    ,
    brown3 = {
        base = { position = { 404, 0 }, corner_size = 8 },
        shadow = default_shadow
    }
    ,
    brown4 = {
        base = { position = { 420, 0 }, corner_size = 8 },
        shadow = default_shadow
    }
    ,
    red = {
        base = { position = { 136, 17 }, corner_size = 8 },
        shadow = default_shadow
    }
}

default_gui["HL_api_section1"] = {
    type = "button_style",
    font = "heading-2",
    horizontal_align = "left",
    default_font_color = gui_color.light_orange,
    default_graphical_set = gui_graphical_set.brown1
}

default_gui["HL_api_section2"] = {
    type = "button_style",
    font = "heading-2",
    horizontal_align = "left",
    default_font_color = gui_color.light_orange,
    default_graphical_set = gui_graphical_set.brown2
}

default_gui["HL_api_section3"] = {
    type = "button_style",
    font = "heading-2",
    horizontal_align = "left",
    default_font_color = gui_color.light_orange,
    default_graphical_set = gui_graphical_set.brown3
}

default_gui["HL_api_section4"] = {
    type = "button_style",
    font = "heading-2",
    horizontal_align = "left",
    default_font_color = gui_color.light_orange,
    default_graphical_set = gui_graphical_set.brown4
}
