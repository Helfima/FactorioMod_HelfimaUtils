-------------------------------------------------------------------------------
---Class to build rule edition dialog
---@class RuntimaApiView : Form
RuntimaApiView = newclass(Form, function(base, classname)
    Form.init(base, classname)
    base.inner_frame = defines.mod.styles.frame.inside_deep
    base.auto_clear = true
    base.mod_menu = false
    base.submenu_enabled = true
    base.content_padding = 0
end)


-------------------------------------------------------------------------------
---On Style
---@param styles table
---@param width_main number
---@param height_main number
function RuntimaApiView:on_style(styles, width_main, height_main)
    styles.flow_panel = {
        minimal_width = width_main * 0.8,
        height = height_main * 0.8
    }
end

-------------------------------------------------------------------------------
---Is visible
---@return boolean
function RuntimaApiView:is_visible()
    return Player.is_admin()
end

-------------------------------------------------------------------------------
---Is special
---@return boolean
function RuntimaApiView:is_special()
    return true
end

-------------------------------------------------------------------------------
---On initialization
function RuntimaApiView:on_init()
    self.panel_caption = { "HelfimaUtils.runtime-api-title" }
end

-------------------------------------------------------------------------------
---Get Button Sprites
---@return string,string
function RuntimaApiView:get_button_sprites()
    return defines.sprites.database_method.white, defines.sprites.database_method.black
end

-------------------------------------------------------------------------------
---On before open
---@param event EventModData
function RuntimaApiView:on_open_before(event)
    if event.information ~= nil then
        RuntimeApi.set_history(event.information.section, event.information.sub_section)
    end
end

-------------------------------------------------------------------------------
---On Update
---@param event EventModData
function RuntimaApiView:on_update(event)
    self:update_runtime_api_menu(event)
    self:update_runtime_api_data(event)
end

---@param event EventModData
function RuntimaApiView:update_runtime_api_menu(event)
    local flow_panel, content_panel, submenu_panel, menu_panel = self:get_panel()
    submenu_panel.style.height = 0

    local menu_flow = GuiElement.add(submenu_panel, GuiTable("filters"):column(2))
    menu_flow.style.horizontal_spacing = 20
    menu_flow.style.vertical_align = "center"

    -- Runtime API
    local runtime_api = RuntimeApi.get_api() or {}
    GuiElement.add(menu_flow, GuiLabel("runtime_api_label"):caption("API Version:"))
    GuiElement.add(menu_flow, GuiLabel("runtime_api_version"):caption(runtime_api["application_version"]))

    GuiElement.add(menu_flow, GuiLabel("runtime_api_input"):caption("Input json"))
    GuiElement.add(menu_flow, GuiTextField(self.classname, "change-runtime-api"))

end

---@param event EventModData
function RuntimaApiView:update_runtime_api_data(event)
    local content_panel = self:get_frame_panel("api",nil,"horizontal")

    local sections = RuntimeApi.get_sections()
    local history = RuntimeApi.get_history()

    local left_panel = GuiElement.add(content_panel, GuiFrameV("navigate"):style(defines.mod.styles.frame.inside_deep))
    left_panel.style.width = 400
    left_panel.style.vertically_stretchable = true
    left_panel.style.margin = 5

    local navigate_panel = GuiElement.add(left_panel, GuiScroll("navigate"))
    navigate_panel.style.horizontally_stretchable = true
    
    local right_panel = GuiElement.add(content_panel, GuiFrameV("information"):style(defines.mod.styles.frame.inside_deep))
    right_panel.style.width = 1000
    right_panel.style.margin = 5
    right_panel.style.padding = 10
    right_panel.style.horizontally_stretchable = true
    right_panel.style.vertically_stretchable = true

    local information_panel = GuiElement.add(right_panel, GuiScroll("information"))
    information_panel.style.horizontally_stretchable = true
    information_panel.style.vertically_stretchable = true

    -- Runtime API
    local runtime_api = RuntimeApi.get_api() or {}
    
    local scroll_element = nil
    local class_sorter = function(t, a, b) return t[b]["name"] > t[a]["name"] end
    for _, section in pairs(sections) do
        local button_section = GuiElement.add(navigate_panel, GuiButton(self.classname, "change-section", section.name):caption(section.localised_name):style(defines.mod.styles.button.section.primary))
        button_section.style.horizontally_stretchable = true
        if section.expand then
            for _, element in spairs(runtime_api[section.name], class_sorter) do
                local button = GuiElement.add(navigate_panel, GuiButton(self.classname, "change-sub-section", section.name, element.name):caption(element.name):style(defines.mod.styles.button.section.secondary))
                button.style.horizontally_stretchable = true
                button.style.left_margin = 30
                if history.section ==  section.name and history.sub_section ==  element.name then
                    button.enabled = false
                    scroll_element = button
                end
            end
        end
    end
    if scroll_element ~= nil then
    -- "in-view" or "top-third"
    navigate_panel.scroll_to_element(scroll_element, "top-third")
    end
    if history.sub_section ~= nil then
        for _, element in pairs(runtime_api[history.section]) do
            if element.name == history.sub_section then
                
                if history.section == "classes" then
                    self:format_class(information_panel, element)
                elseif history.section == "events" then
                    self:format_event(information_panel, element)
                else
                    self:format_element(information_panel, element)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
---On event
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_element(parent, element)
    GuiElement.add(parent, GuiLabel("label"):caption(element.name):style("frame_title"))
    local textbox = GuiElement.add(parent, GuiLabel("description"):caption({"",element.description}):single_line(false))
    textbox.style.width = 900
end

-------------------------------------------------------------------------------
---On event
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_class(parent, element)
    RuntimaApiView:format_element(parent, element)

    self:format_method(parent, element)
    self:format_attribute(parent, element)
end

-------------------------------------------------------------------------------
---On event
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_method(parent, element)
    for key, row in pairs(element.methods) do
        local cell_row = GuiElement.add(parent, GuiFrame("method", row.name):style(defines.mod.styles.frame.colored.gray2))
        cell_row.style.horizontally_stretchable = true
        cell_row.style.vertically_stretchable = false
        local cell_name = GuiElement.add(cell_row, GuiLabel(key, "name"):caption(row.name))
        cell_name.style.width = 200
        local cell_type = GuiElement.add(cell_row, GuiLabel(key, "type"):caption(row.type))
        cell_type.style.width = 200
        GuiElement.add(cell_row, GuiLabel(key, "description"):caption(row.description):single_line(false))
    end
end

-------------------------------------------------------------------------------
---On event
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_attribute(parent, element)
    for key, row in pairs(element.attributes) do
        local cell_row = GuiElement.add(parent, GuiFrame("method", row.name):style(defines.mod.styles.frame.colored.gray2))
        cell_row.style.horizontally_stretchable = true
        cell_row.style.vertically_stretchable = false
        local cell_name = GuiElement.add(cell_row, GuiLink(self.classname, "expand-member", row.name):caption(row.name):font_color(defines.color.brown.goldenrod))
        cell_name.style.minimal_width = 200
        local cell_type = self:format_data_type(cell_row, row)
        cell_type.style.minimal_width = 200
        GuiElement.add(cell_row, GuiLabel(key, "description"):caption(row.description):single_line(false))
    end
end

-------------------------------------------------------------------------------
---On event
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_data_type(parent, element)
    local cell = GuiElement.add(parent, GuiFrame("data_type"):style(defines.mod.styles.frame.invisible))
    local chmod = "RW"
    if element.read_type == nil  then
        chmod = "W"
    end
    if element.write_type == nil  then
        chmod = "R"
    end
    local data = element.read_type or element.write_type
    local info_string = string.format(":: %s", chmod)
    local tooltip = serpent.block(data)
    local info_type = GuiElement.add(cell, GuiLabel("info_type"):caption(info_string):tooltip(tooltip))
    info_type.style.padding = {0,2,0,2}
    info_type.style.width = 40
    local content_type = type(data)
    if content_type == "table" then
        self:format_complex_type(cell, data)
    elseif string.find(data, "Lua",0,true) then
        GuiElement.add(cell, GuiLink(self.classname, "follow-link", "classes", data):caption(data))
    else
        GuiElement.add(cell, GuiLabel("simple"):caption(data))
    end
    return cell
end

-------------------------------------------------------------------------------
---On event
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_complex_type(parent, element, index)
    if element.complex_type == "array" then
        GuiElement.add(parent, GuiLabel("array", index):caption("Array of "))
        local cell_array = GuiElement.add(parent, GuiFlowH())
        self:format_complex_type(cell_array, element.value, index)
    elseif element.complex_type == "union" then
        local cell_union = GuiElement.add(parent, GuiFlowV())
        local append_operator = false
        for option_index, option in pairs(element.options) do
            if append_operator then
                local operator = GuiElement.add(cell_union, GuiLabel("operator", option_index):caption("or"))
                operator.style.padding = {0,2,0,2}
            end
            self:format_complex_type(cell_union, option, option_index)
            append_operator = true
        end
    elseif element.complex_type == "literal" then
        local literal = string.format("\"%s\"", element.value)
        GuiElement.add(parent, GuiLabel("literal", index):caption(literal))
    elseif type(element) == "string" and string.find(element, "Lua",0,true) then
        GuiElement.add(parent, GuiButton(self.classname, "follow-link", element):caption(element):style("helfima_lib_link2"))
    elseif type(element) == "string" then
        GuiElement.add(parent, GuiLabel("string", index):caption(element))
    else
        GuiElement.add(parent, GuiLabel("unknown", index):caption("unknown"):color("red"))
    end
end
-------------------------------------------------------------------------------
---On event
---@param element any
function RuntimaApiView:format_event(parent, element)
    RuntimaApiView:format_element(parent, element)

    --local column_widths = {{column = 1, minimal_width = 200},{column = 2, minimal_width = 100},{column = 3, minimal_width = 100}}
    local table = GuiElement.add(parent, GuiTable("item"):column(3):style(defines.mod.styles.table.bordered_gray))
    table.style.width = 800
    table.style.cell_padding = 5
    for key, row in pairs(element.data) do
        GuiElement.add(table, GuiLabel(key, "attribute"):caption(row.name))
        GuiElement.add(table, GuiLabel(key, "type"):caption(row.type))
        GuiElement.add(table, GuiLabel(key, "description"):caption(row.description):single_line(false))
    end
end

-------------------------------------------------------------------------------
---On event
---@param event EventModData
function RuntimaApiView:on_event(event)
    local sections = RuntimeApi.get_sections()
    local history = RuntimeApi.get_history()

    if event.action == "follow-link" then
        local section = event.item1
        local sub_section = event.item2
        RuntimeApi.set_history(section, sub_section)
        Dispatcher:send(defines.mod.events.on_gui_open, nil, self.classname)
    end

    if event.action == "expand-member" then
        local cell_content = event.element.parent
        local value = event.element.tags
    end

    if event.action == "change-runtime-api" then
        local json_string = event.element.text
        RuntimeApi.set_api(json_string)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "change-section" then
        local section = event.item1
        RuntimeApi.expand_section(section, not(sections[section].expand))
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "change-sub-section" then
        local section = event.item1
        local sub_section = event.item2
        RuntimeApi.set_history(section, sub_section)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end
end