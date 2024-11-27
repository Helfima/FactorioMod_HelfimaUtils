-------------------------------------------------------------------------------
---Class to build rule edition dialog
---@class RuntimaApiView : Form
RuntimaApiView = newclass(Form, function(base, classname)
    Form.init(base, classname)
    base.inner_frame = defines.mod.styles.frame.inside_deep
    base.auto_clear = true
    base.mod_menu = true
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
    local runtime_api = RuntimeApi.get_api()
    GuiElement.add(menu_flow, GuiLabel("runtime_api_label"):caption("API Version:"))
    if runtime_api ~= nil then
        GuiElement.add(menu_flow, GuiLabel("runtime_api_version"):caption(runtime_api["application_version"]))
    else
        GuiElement.add(menu_flow, GuiLabel("runtime_api_version"):caption("Need import runtime API"))
    end

    GuiElement.add(menu_flow, GuiLabel("runtime_api_input"):caption("Input json"))
    GuiElement.add(menu_flow, GuiTextField(self.classname, "change-runtime-api"))

    local runtime_api_imported = User.get_parameter("runtime_api_imported")
    if runtime_api_imported then
        GuiElement.add(menu_flow, GuiLabel("runtime-api-output"):caption("Output json"))
        local api_string = serpent.block(runtime_api, {compact=true})
        GuiElement.add(menu_flow, GuiTextField("runtime-api-output-text"):text(api_string))
        User.set_parameter("runtime_api_imported", false)
    end
end

local class_sorter = function(t, a, b) return t[b]["name"] > t[a]["name"] end
local parameter_sorter = function(t, a, b) return t[b]["order"] > t[a]["order"] end

---@param event EventModData
function RuntimaApiView:update_runtime_api_data(event)
    local content_panel = self:get_frame_panel("api",nil,"horizontal")

    -- Runtime API
    local runtime_api = RuntimeApi.get_api()
    if runtime_api == nil then
        local missing_api = GuiElement.add(content_panel, GuiFlowV())
        GuiElement.add(missing_api, GuiLabel("missing-api"):caption("Put the json string of runtime-api.json in the 'Input json' field and press Enter."))
        GuiElement.add(missing_api, GuiLabel("location-api"):caption("This file can be found in folder game `Factorio_x.x.x\\doc-html\\runtime-api.json` or online https://lua-api.factorio.com/latest/runtime-api.json"))
    else
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

        local scroll_element = nil
        for _, section in pairs(sections) do
            local button_section = GuiElement.add(navigate_panel, GuiButton(self.classname, "change-section", section.name):caption(section.localised_name):style(defines.mod.styles.button.section.primary))
            button_section.style.horizontally_stretchable = true
            if section.expand then
                for index, element in spairs(runtime_api[section.name], class_sorter) do
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
                    elseif history.section == "defines" then
                        self:format_define(information_panel, element)
                    elseif history.section == "concepts" then
                        self:format_concept(information_panel, element)
                    elseif history.section == "global_objects" then
                        self:format_global_objects(information_panel, element)
                    elseif history.section == "global_functions" then
                        self:format_global_fonctions(information_panel, element)
                    else
                        self:format_other(information_panel, element)
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
---Format element
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_element(parent, element)
    GuiElement.add(parent, GuiLabel("label"):caption(element.name):style(defines.mod.styles.label.frame_title))
    GuiElement.add(parent, GuiTree("expand-source"):caption("source..."):source(element):font_color(defines.color.blue.deep_sky_blue))
    local textbox = GuiElement.add(parent, GuiLabel("description"):caption({"",element.description}):single_line(false))
    textbox.style.width = 900
end

-------------------------------------------------------------------------------
---Format Other
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_other(parent, element)
    self:format_element(parent, element)
end

-------------------------------------------------------------------------------
---Format concepts
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_concept(parent, element)
    local cell_header = GuiElement.add(parent, GuiFlowH())
    GuiElement.add(cell_header, GuiLabel("label"):caption(element.name):style(defines.mod.styles.label.frame_title))
    GuiElement.add(parent, GuiTree("expand-source"):caption("source..."):source(element):font_color(defines.color.blue.deep_sky_blue))
    local textbox = GuiElement.add(parent, GuiLabel("description"):caption({"",element.description}):single_line(false))
    textbox.style.width = 900
    
    local cell_detail = GuiElement.add(parent, GuiFrameV("detail"):style(defines.mod.styles.frame.colored.gray2))
    cell_detail.style.horizontally_stretchable = true
    cell_detail.style.vertically_stretchable = false
    cell_detail.style.margin = {2,0,0,0}
    cell_detail.style.padding = {0,0,0,10}
    cell_detail.visible = true

    self:format_single_type(cell_detail, element)
    self:format_parameters(cell_detail, element.type)
    self:format_variant_parameter_groups(cell_detail, element.type)
    self:format_options(cell_detail, element.type)

    if element.type.complex_type == "LuaStruct" then
        self:format_attribute(cell_detail, element.type)
    end
end

-------------------------------------------------------------------------------
---Format global objects
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_global_objects(parent, element)
    local cell_header = GuiElement.add(parent, GuiFlowH())
    GuiElement.add(cell_header, GuiLabel("label"):caption(element.name):style(defines.mod.styles.label.frame_title))
    GuiElement.add(parent, GuiTree("expand-source"):caption("source..."):source(element):font_color(defines.color.blue.deep_sky_blue))
    local textbox = GuiElement.add(parent, GuiLabel("description"):caption({"",element.description}):single_line(false))
    textbox.style.width = 900
    
    local cell_detail = GuiElement.add(parent, GuiFrameV("detail"):style(defines.mod.styles.frame.colored.gray2))
    cell_detail.style.horizontally_stretchable = true
    cell_detail.style.vertically_stretchable = false
    cell_detail.style.margin = {2,0,0,0}
    cell_detail.style.padding = {0,0,0,10}
    cell_detail.visible = true

    self:format_single_type(cell_detail, element)
end

-------------------------------------------------------------------------------
---Format global functions
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_global_fonctions(parent, element)
    local cell_header = GuiElement.add(parent, GuiFlowH())
    GuiElement.add(cell_header, GuiLabel("label"):caption(element.name):style(defines.mod.styles.label.frame_title))
    GuiElement.add(parent, GuiTree("expand-source"):caption("source..."):source(element):font_color(defines.color.blue.deep_sky_blue))
    local textbox = GuiElement.add(parent, GuiLabel("description"):caption({"",element.description}):single_line(false))
    textbox.style.width = 900
    
    local cell_detail = GuiElement.add(parent, GuiFrameV("detail"):style(defines.mod.styles.frame.colored.gray2))
    cell_detail.style.horizontally_stretchable = true
    cell_detail.style.vertically_stretchable = false
    cell_detail.style.margin = {2,0,0,0}
    cell_detail.style.padding = {0,0,0,10}
    cell_detail.visible = true

    self:format_parameters(cell_detail, element)
    self:format_return_values(cell_detail, element)
end

-------------------------------------------------------------------------------
---Format single type
---@param parent LuaGuiElement
---@param element any
---@param skip_title? boolean
function RuntimaApiView:format_single_type(parent, element, skip_title)
    if element.type.full_format == false or type(element.type == "string")  then
        if not(skip_title) then
            GuiElement.add(parent, GuiLabel("type-title"):caption("Type"):style(defines.mod.styles.label.heading_2))
        end
        local cell_frame = GuiElement.add(parent, GuiFrameV("frame-type"):style(defines.mod.styles.frame.colored.gray3))
        cell_frame.style.horizontally_stretchable = true
        cell_frame.style.margin = {5,5,5,10}
        cell_frame.style.padding = 4

        local cell_row = GuiElement.add(cell_frame, GuiFrame("type-label"):style(defines.mod.styles.frame.colored.gray7))
        cell_row.style.horizontally_stretchable = true
        cell_row.style.vertically_stretchable = false
        cell_row.style.margin = 0
        cell_row.style.padding = 2
        -- raise name
        local cell_name = GuiElement.add(cell_row, GuiLabel("type-name"):caption(element.name))
        cell_name.style.width = 200
        -- return type
        local cell_type = GuiElement.add(cell_row, GuiFlowH())
        if type(element.type) == "table" and element.type.complex_type == "union" then
            element.type.union_direction = defines.mod.direction.horizontal
        end
        self:format_complex_type(cell_type, element.type)
        if element.optional == true then
            GuiElement.add(cell_type, GuiLabel("parameter-optional"):caption("?"))
        end
    end
end

-------------------------------------------------------------------------------
---Format classe
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_class(parent, element)
    self:format_element(parent, element)

    self:format_method(parent, element)
    self:format_attribute(parent, element)
end

-------------------------------------------------------------------------------
---Format method
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_method(parent, element)
    if element.methods == nil or table_size(element.methods) == 0 then return end

    local title = GuiElement.add(parent, GuiLabel("method-title"):caption("Methods:"):style(defines.mod.styles.label.bold))
    title.style.padding = {5,10,5,10}

    for key, row in pairs(element.methods) do
        local cell_member = GuiElement.add(parent, GuiFlowV())

        local cell_row = GuiElement.add(cell_member, GuiFrame("method", row.name):style(defines.mod.styles.frame.colored.gray2))
        cell_row.style.horizontally_stretchable = true
        cell_row.style.vertically_stretchable = false
        
        -- member name
        local cell_name = GuiElement.add(cell_row, GuiFlowH())
        cell_name.style.width = 400
        GuiElement.add(cell_name, GuiLink(self.classname, "expand-member", "method", row.name):tags(row):caption(row.name):font_color(defines.color.brown.goldenrod))
        self:format_method_arguments(cell_name, row)
        -- member description
        GuiElement.add(cell_row, GuiLabel("method-description"):caption(row.description):single_line(false))
    end
end

-------------------------------------------------------------------------------
---Format arguments of method
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_method_arguments(parent, element)
    local argument_string = "()"
    if table_size(element.parameters) > 0 then
        local arguments = {}
        for key, parameter in spairs(element.parameters, parameter_sorter) do
            local argument = parameter.name
            if parameter.optional == true then
                argument = string.format("%s?", parameter.name)
            end
            table.insert(arguments, argument)
        end
        if element.format ~= nil and element.format.takes_table == true then
            argument_string = string.format("{%s}", table.concat(arguments, ", "))
        else
            argument_string = string.format("(%s)", table.concat(arguments, ", "))
        end
    end
    GuiElement.add(parent, GuiLabel("method-description"):caption(argument_string):single_line(false))
end
-------------------------------------------------------------------------------
---Format method detail
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_method_detail(parent, element)
    local cell_detail = GuiElement.add(parent, GuiFrameV("detail"):style(defines.mod.styles.frame.colored.gray2))
    cell_detail.style.horizontally_stretchable = true
    cell_detail.style.vertically_stretchable = false
    cell_detail.style.margin = {2,0,0,0}
    cell_detail.style.padding = {0,0,0,10}
    cell_detail.visible = true

    GuiElement.add(cell_detail, GuiTree("expand-source"):caption("source..."):source(element):font_color(defines.color.blue.deep_sky_blue))

    self:format_parameters(cell_detail, element)
    self:format_variant_parameter_groups(cell_detail, element)
    self:format_return_values(parent, element)
    

    if element.raises ~= nil and table_size(element.raises) > 0 then
        GuiElement.add(cell_detail, GuiLabel("raises"):caption("Raised events"):style(defines.mod.styles.label.heading_2))
        local cell_frame = GuiElement.add(cell_detail, GuiFrameV("frame-raises"):style(defines.mod.styles.frame.colored.gray4))
        cell_frame.style.horizontally_stretchable = true
        cell_frame.style.margin = {5,5,5,10}
        cell_frame.style.padding = 4

        for key, raise in pairs(element.raises) do
            local cell_row = GuiElement.add(cell_frame, GuiFrame("raise", raise.name):style(defines.mod.styles.frame.colored.gray7))
            cell_row.style.horizontally_stretchable = true
            cell_row.style.vertically_stretchable = false
            cell_row.style.margin = 0
            cell_row.style.padding = 2
            -- raise name
            local cell_name = GuiElement.add(cell_row, GuiFlowH())
            cell_name.style.width = 400
            GuiElement.add(cell_row, GuiLabel("raise-name"):caption(raise.name))
            if raise.optional == true then
                GuiElement.add(cell_name, GuiLabel("raise-optional", key):caption("?"))
            end
            -- raise description
            GuiElement.add(cell_row, GuiLabel("raise-description"):caption(raise.description):single_line(false))
        end
    end

    self:format_subclasses(cell_detail, element)
end
-------------------------------------------------------------------------------
---Format parameters
---@param parent LuaGuiElement
---@param element any
---@param skip_title? boolean
function RuntimaApiView:format_parameters(parent, element, skip_title)
    if element.parameters ~= nil and table_size(element.parameters) > 0 then
        if not(skip_title) then
            GuiElement.add(parent, GuiLabel("parameters"):caption("Parameters"):style(defines.mod.styles.label.heading_2))
        end
        local cell_frame = GuiElement.add(parent, GuiFrameV("frame-parameters"):style(defines.mod.styles.frame.colored.gray3))
        cell_frame.style.horizontally_stretchable = true
        cell_frame.style.margin = {5,5,5,10}
        cell_frame.style.padding = 4

        for key, parameter in spairs(element.parameters, parameter_sorter) do
            local cell_row = GuiElement.add(cell_frame, GuiFrame("parameter", key):style(defines.mod.styles.frame.colored.gray7))
            cell_row.style.horizontally_stretchable = true
            cell_row.style.vertically_stretchable = false
            cell_row.style.margin = 0
            cell_row.style.padding = 2
            -- raise name
            local cell_name = GuiElement.add(cell_row, GuiLabel("parameter-name"):caption(parameter.name))
            cell_name.style.width = 200
            -- return type
            local cell_type = GuiElement.add(cell_row, GuiFlowH())
            cell_type.style.width = 200
            self:format_complex_type(cell_type, parameter.type, key)
            if parameter.optional == true then
                GuiElement.add(cell_type, GuiLabel("parameter-optional", key):caption("?"))
            end
            -- raise description
            GuiElement.add(cell_row, GuiLabel("parameter-description"):caption(parameter.description):single_line(false))
        end
    end
end

-------------------------------------------------------------------------------
---Format return values
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_return_values(parent, element)
    if element.return_values ~= nil and table_size(element.return_values) > 0 then
        GuiElement.add(parent, GuiLabel("return_values"):caption("Return values"):style(defines.mod.styles.label.heading_2))
        local cell_frame = GuiElement.add(parent, GuiFrameV("frame-return-value"):style(defines.mod.styles.frame.colored.gray4))
        cell_frame.style.horizontally_stretchable = true
        cell_frame.style.margin = {5,5,5,10}
        cell_frame.style.padding = 4

        for key, return_value in pairs(element.return_values) do
            local cell_row = GuiElement.add(cell_frame, GuiFrame("return-value", key):style(defines.mod.styles.frame.colored.gray7))
            cell_row.style.horizontally_stretchable = true
            cell_row.style.vertically_stretchable = false
            cell_row.style.margin = 0
            cell_row.style.padding = 2
            -- return type
            local cell_type = GuiElement.add(cell_row, GuiFlowH())
            cell_type.style.width = 400
            self:format_complex_type(cell_type, return_value.type, key)
            if return_value.optional == true then
                GuiElement.add(cell_type, GuiLabel("return-value-optional", key):caption("?"))
            end
        
            -- raise description
            GuiElement.add(cell_row, GuiLabel("return-value-description"):caption(return_value.description):single_line(false))
        end
    end
end

-------------------------------------------------------------------------------
---Format options
---@param parent LuaGuiElement
---@param element any
---@param skip_title? boolean
function RuntimaApiView:format_options(parent, element, skip_title)
    if element.options ~= nil and table_size(element.options) > 0 then

        if element.full_format == true then
            if not(skip_title) then
                GuiElement.add(parent, GuiLabel("options"):caption("Union member"):style(defines.mod.styles.label.heading_2))
            end
            local cell_frame = GuiElement.add(parent, GuiFrameV("frame-options"):style(defines.mod.styles.frame.colored.gray3))
            cell_frame.style.horizontally_stretchable = true
            cell_frame.style.margin = {5,5,5,10}
            cell_frame.style.padding = 4
            
            for key, option in spairs(element.options, parameter_sorter) do
                local cell_row = GuiElement.add(cell_frame, GuiFrame("option", key):style(defines.mod.styles.frame.colored.gray7))
                cell_row.style.horizontally_stretchable = true
                cell_row.style.vertically_stretchable = false
                cell_row.style.margin = 0
                cell_row.style.padding = 2
                -- option
                local cell_type = GuiElement.add(cell_row, GuiFlowH())
                cell_type.style.width = 200
                self:format_complex_type(cell_type, option, key)

                -- raise description
                GuiElement.add(cell_row, GuiLabel("option-description"):caption(option.description):single_line(false))
            end
        else
            for key, option in spairs(element.options, parameter_sorter) do
                if option.complex_type == "table" then
                    self:format_parameters(parent, option, false)
                end
            end
        end
    end
end
-------------------------------------------------------------------------------
---Format variant parameter groups
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_variant_parameter_groups(parent, element)
    if element.variant_parameter_groups ~= nil and table_size(element.variant_parameter_groups) > 0 then
        GuiElement.add(parent, GuiLabel("variant-parameter-groups"):caption(element.variant_parameter_description):style(defines.mod.styles.label.heading_2))
        for index, variant_parameter_group in pairs(element.variant_parameter_groups) do
            local cell_variant = GuiElement.add(parent, GuiFlowV())
            cell_variant.style.margin = {5,5,5,10}
            
            local cell_frame = GuiElement.add(cell_variant, GuiFrameV("variant-parameter-group", index):style(defines.mod.styles.frame.colored.gray3))
            cell_frame.style.horizontally_stretchable = false
            cell_frame.style.margin = 2
            cell_frame.style.padding = 2
            GuiElement.add(cell_frame, GuiLabel("variant-parameter-group", "title"):caption(variant_parameter_group.name):style(defines.mod.styles.label.subheader))

            self:format_parameters(cell_variant, variant_parameter_group, true)
        end
    end
end
-------------------------------------------------------------------------------
---Format attributes
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_attribute(parent, element)
    if element.attributes == nil or table_size(element.attributes) == 0 then return end

    local title = GuiElement.add(parent, GuiLabel("attributes-title"):caption("Attributes:"):style(defines.mod.styles.label.bold))
    title.style.padding = {5,10,5,10}

    for key, row in pairs(element.attributes) do
        local cell_member = GuiElement.add(parent, GuiFlowV())

        local cell_row = GuiElement.add(cell_member, GuiFrame("method", row.name):style(defines.mod.styles.frame.colored.gray2))
        cell_row.style.horizontally_stretchable = true
        cell_row.style.vertically_stretchable = false
        -- member name
        local cell_name = GuiElement.add(cell_row, GuiLink(self.classname, "expand-member", "attribute", row.name):tags(row):caption(row.name):font_color(defines.color.brown.goldenrod))
        cell_name.style.minimal_width = 200
        -- member type
        local cell_type = self:format_data_type(cell_row, row)
        cell_type.style.minimal_width = 200
        -- memeber description
        GuiElement.add(cell_row, GuiLabel(key, "description"):caption(row.description):single_line(false))
    end
end

-------------------------------------------------------------------------------
---Format parameter detail
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_parameter_detail(parent, element)
    local cell_detail = GuiElement.add(parent, GuiFrameV("detail"):style(defines.mod.styles.frame.colored.gray2))
    cell_detail.style.horizontally_stretchable = true
    cell_detail.style.vertically_stretchable = false
    cell_detail.style.margin = {2,0,0,0}
    cell_detail.style.padding = {0,0,0,10}
    cell_detail.visible = true

    GuiElement.add(cell_detail, GuiTree("expand-source"):caption("source..."):source(element):font_color(defines.color.blue.deep_sky_blue))

    self:format_subclasses(cell_detail, element)
end

-------------------------------------------------------------------------------
---Format subclasses
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_subclasses(parent, element)
    if element.subclasses ~= nil and table_size(element.subclasses) > 0 then
        local info = nil
        for _, subclasse in pairs(element.subclasses) do
            if info ~= nil then
                info = info .. " or " .. subclasse
            else
                info = subclasse
            end
        end
        GuiElement.add(parent, GuiLabel("subclasses"):caption({"", "Can only be used if this is ", info}):font_color(defines.color.yellow.khaki))
    end
end
-------------------------------------------------------------------------------
---Format data type
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
---Format complex type
---@param parent LuaGuiElement
---@param element any
---@param index? number
function RuntimaApiView:format_complex_type(parent, element, index)
    if element.complex_type == "function" then
        -- function
        local cell_function = GuiElement.add(parent, GuiFlowH())
        GuiElement.add(cell_function, GuiLabel("function-start", index):caption("function("))
        for key, parameter in pairs(element.parameters) do
            GuiElement.add(cell_function, GuiLink(self.classname, "follow-link", "concepts", parameter, key):caption(parameter))
            if key > 1 then
                GuiElement.add(cell_function, GuiLabel("function-separator", key):caption(","))
            end
        end
        GuiElement.add(cell_function, GuiLabel("function-end", index):caption(")"))
    elseif element.complex_type == "dictionary" then
        -- dictionary
        local cell_dictionary = GuiElement.add(parent, GuiFlowH())
        GuiElement.add(cell_dictionary, GuiLabel("dictionary-start", index):caption("dictionary["))
        self:format_complex_type(cell_dictionary, element.key, 0)
        GuiElement.add(cell_dictionary, GuiLabel("dictionary-separator", index):caption("->"))
        self:format_complex_type(cell_dictionary, element.value, 1)
        GuiElement.add(cell_dictionary, GuiLabel("dictionary-end", index):caption("]"))
    elseif element.complex_type == "table" then
        -- table
        GuiElement.add(parent, GuiLabel("table", index):caption("table"))
    elseif element.complex_type == "builtin" then
        -- table
        GuiElement.add(parent, GuiLabel("builtin", index):caption("{}"))
    elseif element.complex_type == "LuaStruct" then
        -- table
        GuiElement.add(parent, GuiLabel("LuaStruct", index):caption("LuaStruct"))
    elseif element.complex_type == "array" then
        -- array
        GuiElement.add(parent, GuiLabel("array", index):caption("Array of "))
        local cell_array = GuiElement.add(parent, GuiFlowH())
        self:format_complex_type(cell_array, element.value, index)
    elseif element.complex_type == "union" then
        -- union
        local direction = element.union_direction or defines.mod.direction.vertical
        local flow = GuiFlowH()
        if direction == defines.mod.direction.vertical then
            flow = GuiFlowV()
        end
        local cell_union = GuiElement.add(parent, flow)
        local append_operator = false
        for option_index, option in pairs(element.options) do
            if append_operator then
                local operator = GuiElement.add(cell_union, GuiLabel("operator", option_index):caption("or"))
                operator.style.padding = {0,2,0,2}
            end
            self:format_complex_type(cell_union, option, option_index)
            append_operator = true
        end
    elseif element.complex_type == "tuple" then
        -- tuple
        local cell_tuple = GuiElement.add(parent, GuiFlowH())
        GuiElement.add(cell_tuple, GuiLabel("tuple-start", index):caption("{"))
        for key, value in pairs(element.values) do
            if key > 1 then
                GuiElement.add(cell_tuple, GuiLabel("tuple-separator", key):caption(", "))
            end
            self:format_complex_type(cell_tuple, value, key)
        end
        GuiElement.add(cell_tuple, GuiLabel("tuple-end", index):caption("}"))
    elseif element.complex_type == "type" then
        -- type
        self:format_complex_type(parent, element.value, index)
    elseif element.complex_type == "literal" then
        -- literal
        local literal = string.format("\"%s\"", element.value)
        GuiElement.add(parent, GuiLabel("literal", index):caption(literal))
    elseif type(element) == "string" and string.find(element, "Lua",0,true) then
        -- classes
        GuiElement.add(parent, GuiLink(self.classname, "follow-link", "classes", element, index):caption(element))
    elseif type(element) == "string" and string.find(element, "defines",0,true) then
        -- defines
        local value = string.gsub(element, "defines.", "")
        GuiElement.add(parent, GuiLink(self.classname, "follow-link", "defines", value, index):caption(value))
    elseif type(element) == "string" then
        -- string
        GuiElement.add(parent, GuiLink(self.classname, "follow-link", "concepts", element, index):caption(element))
    else
        -- unknown
        GuiElement.add(parent, GuiLabel("unknown", index):caption("unknown"):color("red"))
    end
end
-------------------------------------------------------------------------------
---Format events
---@param parent LuaGuiElement
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
---Format defines
---@param parent LuaGuiElement
---@param element any
function RuntimaApiView:format_define(parent, element)
    RuntimaApiView:format_element(parent, element)

    if element.values then
        local prefix = string.format("define.%s.", element.name)
        self:format_define_values(parent, prefix, element)
    end

    if element.subkeys then
        local prefix = string.format("define.%s", element.name)
        self:format_define_subkeys(parent, prefix, element)
    end
end

-------------------------------------------------------------------------------
---Format define subkeys
---@param parent LuaGuiElement
---@param prefix string
---@param element any
function RuntimaApiView:format_define_subkeys(parent, prefix, element)
    if element.subkeys then
        for _, subkey in pairs(element.subkeys) do
            local prefix = string.format("%s.%s", prefix, subkey.name)
            if subkey.subkeys then
                self:format_define_subkeys(parent, prefix, subkey)
            else
                self:format_define_values(parent, prefix, subkey)
            end
        end
    end
end

-------------------------------------------------------------------------------
---Format define values
---@param parent LuaGuiElement
---@param prefix string
---@param element any
function RuntimaApiView:format_define_values(parent, prefix, element)
    --local column_widths = {{column = 1, minimal_width = 200},{column = 2, minimal_width = 100},{column = 3, minimal_width = 100}}
    local table = GuiElement.add(parent, GuiTable("table", prefix):column(2):style(defines.mod.styles.table.bordered_gray))
    table.style.width = 900
    table.style.cell_padding = 5
    if element.values then
        for key, row in pairs(element.values) do
            local name = string.format("%s.%s", prefix, row.name)
            GuiElement.add(table, GuiLabel(key, "attribute"):caption(name))
            GuiElement.add(table, GuiLabel(key, "description"):caption(row.description):single_line(false))
        end
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
        if event.item1 == "method" then
            local cell_content = event.element.parent.parent.parent
            if table.contains(cell_content.children_names, "detail")  then
                cell_content["detail"].destroy()
            else
                self:format_method_detail(cell_content, event.element.tags)
            end
        end
        if event.item1 == "attribute" then
            local cell_content = event.element.parent.parent
            if table.contains(cell_content.children_names, "detail")  then
                cell_content["detail"].destroy()
            else
                self:format_method_detail(cell_content, event.element.tags)
            end
        end
    end

    if event.action == "change-runtime-api" then
        local json_string = event.element.text
        RuntimeApi.set_api(json_string)
        User.set_parameter("runtime_api_imported", true)
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