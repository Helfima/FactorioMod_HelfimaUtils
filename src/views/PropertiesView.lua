-------------------------------------------------------------------------------
---Class to build rule edition dialog
---@class PropertiesView : Form
PropertiesView = newclass(Form, function(base, classname)
    Form.init(base, classname)
    base.auto_clear = true
    base.mod_menu = true
    base.submenu_enabled = true
end)


-------------------------------------------------------------------------------
---On Style
---@param styles table
---@param width_main number
---@param height_main number
function PropertiesView:on_style(styles, width_main, height_main)
    styles.flow_panel = {
        width = width_main * 0.8,
        height = height_main * 0.8
    }
end

-------------------------------------------------------------------------------
---On initialization
function PropertiesView:on_init()
    self.panel_caption = { "HelfimaUtils.properties-title" }
end

-------------------------------------------------------------------------------
---For Bind Dispatcher Event
function PropertiesView:on_bind()
    Dispatcher:bind(defines.mod.events.on_before_delete_cache, self, self.on_before_delete_cache)
end

-------------------------------------------------------------------------------
---On Update
---@param event EventModData
function PropertiesView:on_before_delete_cache(event)
    -- remove all data
    Dispatcher:send(defines.mod.events.on_gui_update, nil, PropertiesView.classname)
end

-------------------------------------------------------------------------------
---Get Button Sprites
---@return string,string
function PropertiesView:get_button_sprites()
  return defines.sprites.database_schema.white, defines.sprites.database_schema.black
end

-------------------------------------------------------------------------------
---On before open
---@param event EventModData
function PropertiesView:on_open_before(event)
end

-------------------------------------------------------------------------------
---On Update
---@param event EventModData
function PropertiesView:on_update(event)
    self:update_properties_menu(event)
    self:update_properties_data(event)
end

---@param event EventModData
function PropertiesView:update_properties_menu(event)
    local flow_panel, content_panel, submenu_panel, menu_panel = self:get_panel()
    submenu_panel.style.height = 0

    local left_panel = GuiElement.add(submenu_panel, GuiFlowH("left"))
    local right_panel = GuiElement.add(submenu_panel, GuiFlowH("right"))
    right_panel.style.left_margin = 20

    local left_flow = GuiElement.add(left_panel, GuiTable("filters"):column(2))
    left_flow.style.horizontal_spacing = 5
    left_flow.style.vertical_align = "center"

    -- selector
    GuiElement.add(left_flow, GuiLabel("choose-label"):caption("Choose:"))

    local cell_selector = GuiElement.add(left_flow, GuiFlowH("selector"))
    cell_selector.style.horizontal_spacing = 5


    local items = {"achievement","decorative","entity","equipment","fluid","item","item-group","recipe","signal","technology","tile","asteroid-chunk","space-location","item-with-quality","entity-with-quality","recipe-with-quality","equipment-with-quality"}
    local selected = User.get_parameter("type_choosed") or "item"
    GuiElement.add(cell_selector, GuiDropDown(self.classname, "type-choose"):items(items, selected))

    local choose_type = string.format("%s", selected)
    local selector = GuiElement.add(cell_selector, GuiButton(self.classname, "element-choose"):caption("Selector"))

    -- filter
    GuiElement.add(left_flow, GuiLabel("filter-property-label"):caption("Filter:"))
    local filter_value = User.get_parameter("filter-property")
    local filter_field = GuiElement.add(left_flow, GuiTextField(self.classname, "filter-property", "onchange"):text(filter_value))
    filter_field.style.width = 300
    
    local right_flow = GuiElement.add(right_panel, GuiTable("filters"):column(2))
    right_flow.style.horizontal_spacing = 5
    right_flow.style.vertical_align = "center"

    -- Runtime API
    local runtime_api = RuntimeApi.get_api()
    GuiElement.add(right_flow, GuiLabel("runtime_api_label"):caption("API Version:"))
    if runtime_api ~= nil then
        GuiElement.add(right_flow, GuiLabel("runtime_api_version"):caption(runtime_api["application_version"]))
    else
        GuiElement.add(right_flow, GuiLabel("runtime_api_version"):caption("Need import runtime API"))
    end

    ---nil values
    local switch_nil = "left"
    if User.get_parameter("filter_property_nil") == true then
        switch_nil = "right"
    end
    GuiElement.add(right_flow, GuiLabel("filter-nil-property"):caption("Hide nil values:"))
    GuiElement.add(right_flow, GuiSwitch(self.classname, "filter-property-switch", "nil"):state(switch_nil):leftLabel("Off"):rightLabel("On"))

    ---difference values
    local switch_nil = "left"
    if User.get_parameter("filter_property_diff") == true then
        switch_nil = "right"
    end
    GuiElement.add(right_flow, GuiLabel("filter-difference-property"):caption("Show differences:"))
    GuiElement.add(right_flow, GuiSwitch(self.classname, "filter-property-switch", "diff"):state(switch_nil):leftLabel("Off"):rightLabel( "On"))

end

---@param event EventModData
function PropertiesView:update_properties_data(event)
    local content_panel = self:get_scroll_panel("data")

    local elements_choosed = User.get_parameter("elements_choosed") or {}

    if table_size(elements_choosed) == 0 then
        GuiElement.add(content_panel, GuiLabel("nothing"):caption("Choose a element!"))
        return
    end

    local prototype_keys = {}
    local prototypes = {header={},attributes={}}
    for key, element_choosed in pairs(elements_choosed) do
        prototype_keys[key] = true
        local prototype = self:get_data(element_choosed)
        for _, attribute in pairs(prototype.header) do
            local attribute_key = attribute.name
            if prototypes.header[attribute_key] == nil then
                prototypes.header[attribute_key] = {name=attribute.name, attribute.description, type=attribute.type, values={}}
            end
            prototypes.header[attribute_key]["values"][key] = attribute.value
        end
        for _, attribute in pairs(prototype.attributes) do
            local attribute_key = attribute.name
            if prototypes.attributes[attribute_key] == nil then
                prototypes.attributes[attribute_key] = {name=attribute.name, attribute.description, type=attribute.type, values={}}
            end
            prototypes.attributes[attribute_key]["values"][key] = attribute.value
        end
    end
    local column_count = 2 + table_size(prototype_keys)

    local table = GuiElement.add(content_panel, GuiTable("item"):column(column_count):style(defines.mod.styles.table.bordered_gray))

    local sorter = function(t, a, b) return t[b]["name"] > t[a]["name"] end
    for _, attribute in spairs(prototypes.header, sorter) do
        local cell_name = GuiElement.add(table, GuiFlowH():tooltip(attribute.description))
        GuiElement.add(cell_name, GuiLabel("content"):caption(attribute.name):style(defines.mod.styles.label.heading_2))
        
        local cell_type = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_type, GuiLabel("content"):caption(attribute.type))
        
        for key, _ in pairs(prototype_keys) do
            local value = attribute.values[key]
            local cell_content = GuiElement.add(table, GuiFlowH())
            if attribute.type == "sprite" then
                GuiElement.add(cell_content, GuiButtonSprite(self.classname, "element-delete", key):sprite(value.type, value.name))
            else
                GuiElement.add(cell_content, GuiLabel("content"):caption(value))
            end
        end
    end

    for _, attribute in spairs(prototypes.attributes, sorter) do
        if not(User.get_parameter("filter_property_nil") and PropertiesView.values_is_nil(attribute.values)) and
        not(User.get_parameter("filter_property_diff") and PropertiesView.values_is_same(attribute.values)) then
            local cell_name = GuiElement.add(table, GuiFlowH())
            GuiElement.add(cell_name, GuiLabel("content"):caption(attribute.name):tooltip(attribute.description):style(defines.mod.styles.label.heading_2))
            if attribute.description ~= nil and attribute.description ~= '' then
                local sprite = GuiElement.add(cell_name, GuiSprite("info"):sprite("menu", defines.sprites.status_information.white):tooltip(attribute.description))
                sprite.style.size = 15
                sprite.style.stretch_image_to_widget_size = true
                sprite.style.margin = 5
            end
            
            local cell_type = GuiElement.add(table, GuiFlowH())
            GuiElement.add(cell_type, GuiLabel("content"):caption(attribute.type))
            
            for key, _ in pairs(prototype_keys) do
                local value = attribute.values[key]
                self:update_attribute_value(table, value)
            end
        end
    end
end

---@param parent LuaGuiElement
---@param content any
function PropertiesView:update_userdata(parent, content)
    local table = GuiElement.add(parent, GuiTable("item"):column(3):style(defines.mod.styles.table.bordered_gray))
    local sorter = function(t, a, b) return t[b]["name"] > t[a]["name"] end
    for _, attribute in spairs(content.attributes, sorter) do
        if attribute.value ~= nil then
            local cell_name = GuiElement.add(table, GuiFlowH())
            GuiElement.add(cell_name, GuiLabel("content"):caption(attribute.name):tooltip(attribute.description):font_color(defines.color.purple.violet))
            
            local cell_type = GuiElement.add(table, GuiFlowH())
            GuiElement.add(cell_type, GuiLabel("content"):caption(attribute.type))
            
            self:update_attribute_value(table, attribute.value)
        end
    end
end

function PropertiesView:update_attribute_value(table, value)
    local value_type = type(value)
    local cell_content = GuiElement.add(table, GuiFlowH())
    if value_type == "userdata" then
        self:update_attribute_userdata(cell_content, value)
    elseif value_type == "table" then
        local size = table_size(value)
        if size == 0 then
            GuiElement.add(cell_content, GuiLabel("content"):caption("{empty}"):color("red"))
        elseif size < 10 then
            self:update_attribute_table(cell_content, value)
        else
            GuiElement.add(cell_content, GuiLink(self.classname, "expand-content"):caption({"HelfimaUtils.expand-content"}):tags({value=value}):font_color(defines.color.blue.deep_sky_blue))
        end
    elseif value_type == "boolean" then
        if value then
            GuiElement.add(cell_content, GuiLabel("content"):caption("true"))
        else
            GuiElement.add(cell_content, GuiLabel("content"):caption("false"))
        end
    else
        GuiElement.add(cell_content, GuiLabel("content"):caption(value or ""))
    end
end

function PropertiesView:update_attribute_table(parent, content)
    local table_style = defines.mod.styles.table.bordered_green
    if #content > 0 then
        table_style = defines.mod.styles.table.bordered_yellow
    end
    local table = GuiElement.add(parent, GuiTable("item"):column(2):style(table_style))
    for name, value in pairs(content) do
        local cell_name = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_name, GuiLabel("content"):caption(name))
        local cell_content = GuiElement.add(table, GuiFlowH())

        local content_type = type(value)
        if content_type == "userdata" then
            self:update_attribute_userdata(cell_content, value)
        elseif content_type == "table" then
            local size = table_size(value)
            if size == 0 then
                GuiElement.add(cell_content, GuiLabel("content"):caption("empty table"))
            elseif size < 10 then
                self:update_attribute_table(cell_content, value)
            else
                GuiElement.add(cell_content, GuiLink(self.classname, "expand-content"):caption({"HelfimaUtils.expand-content"}):tags({value=value}):font_color(defines.color.blue.deep_sky_blue))
            end
        else
            GuiElement.add(cell_content, GuiLabel("content"):caption(value))
        end
    end
end

function PropertiesView:update_attribute_userdata(parent, lua_prototype)
    local object_name = lua_prototype.object_name
    local localised_name = lua_prototype.object_name
    pcall(function()
        localised_name = lua_prototype.name
    end)
    local value = self:get_userdata(lua_prototype)
    GuiElement.add(parent, GuiLink(self.classname, "expand-userdata", object_name):tags({value=value}):caption(localised_name):font_color(defines.color.purple.orchid))
end

---Return elementkey
---@param element any
---@return string
function PropertiesView.get_key(element)
    local key = nil
    if element.quality == nil then
        key = string.format("%s_%s", element.type, element.name)
    else
        key = string.format("%s_%s_%s", element.type, element.name, element.quality)
    end
    return key
end

function PropertiesView.values_is_nil(values)
    for key, value in pairs(values) do
        if value ~= nil then
            return false
        end
    end
    return true
end

function PropertiesView.values_is_same(values)
    local first = nil
    for key, value in pairs(values) do
        if first == nil then
            first = value
        else
            if type(value) == "userdata" then
                if value.object_name ~= first.object_name then
                    return false
                end
            elseif type(value) == "table" then
                if not(table_size(value) == 0 and table_size(first) == 0) then
                    local result = PropertiesView.table_is_same(value, first)
                    if result == false then
                        return false
                    end
                end
            else
                if value ~= first then
                    return false
                end
            end
        end
    end
    return true
end

function PropertiesView.table_is_same(table1, table2)
    for key, value1 in pairs(table1) do
        local value2 = table2[key]
        if value2 ~= nil then
            if type(value1) == "userdata" then
                if value1.object_name ~= value2.object_name then
                    return false
                end
            elseif type(value1) == "table" then
                local result = PropertiesView.table_is_same(value1, value2)
                if result == false then
                    return false
                end
            else
                if value1 ~= value2 then
                    return false
                end
            end
        end
    end
    return true
end

-------------------------------------------------------------------------------
---On event
---@param event EventModData
function PropertiesView:on_event(event)

    if event.action == "follow-link" then
        local information = {section="classes", sub_section=event.item1}
        Dispatcher:send(defines.mod.events.on_gui_open, {sender=self.classname, information=information}, "RuntimaApiView")
    end
    
    if event.action == "expand-content" then
        local cell_content = event.element.parent
        local value = event.element.tags.value
        cell_content.clear()
        self:update_attribute_table(cell_content, value)
    end

    if event.action == "expand-userdata" then
        local cell_content = event.element.parent
        local value = event.element.tags.value
        cell_content.clear()
        self:update_userdata(cell_content, value)
    end

    if event.action == "type-choose" then
        local dropdown = event.element
        local type_choosed = dropdown.get_item(dropdown.selected_index)
        User.set_parameter("type_choosed", type_choosed)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "element-choose" then
        local element_type = User.get_parameter("type_choosed") or "item"
        Dispatcher:send(defines.mod.events.on_gui_open, {sender=self.classname, element_type=element_type}, "HLSelector")
    end

    if event.action == "selector-return" then
        local element_key = PropertiesView.get_key(event.selected_element)
        local elements_choosed = User.get_parameter("elements_choosed") or {}
        elements_choosed[element_key] = event.selected_element
        User.set_parameter("elements_choosed", elements_choosed)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "element-delete" then
        local element_key = event.item1
        local elements_choosed = User.get_parameter("elements_choosed") or {}
        elements_choosed[element_key] = nil
        User.set_parameter("elements_choosed", elements_choosed)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "filter-property-switch" then
        local switch_nil = event.element.switch_state == "right"
        local parameter_name = string.format("filter_property_%s", event.item1)
        User.set_parameter(parameter_name, switch_nil)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end
end

function PropertiesView:get_data(element_choosed)
    local prototype = {header={},attributes={}}
    table.insert(prototype.header, self:get_attribute_data("icon", nil, "sprite", element_choosed))
    table.insert(prototype.header, self:get_attribute_data("type", nil, "string", element_choosed.type))
    table.insert(prototype.header, self:get_attribute_data("name", nil, "string", element_choosed.name))
    table.insert(prototype.header, self:get_attribute_data("quality", nil, "string", element_choosed.quality))

    local lua_prototype= self:get_lua_prototype(element_choosed)
    table.insert(prototype.header, self:get_attribute_data("lua_prototype", nil, "string", lua_prototype.object_name))
    local lua_classe = RuntimeApi.get_classe(lua_prototype.object_name)
    while lua_classe ~= nil do
        for _, lua_attribute in pairs(lua_classe.attributes) do
            local content = nil
            pcall(function()
                content = lua_prototype[lua_attribute.name]
            end)
            local content_type = type(content)
            table.insert(prototype.attributes, self:get_attribute_data(lua_attribute.name, lua_attribute.description, content_type,content))
        end
        lua_classe = RuntimeApi.get_classe(lua_classe.parent)
    end
    return prototype
end

function PropertiesView:get_userdata(lua_prototype)
    local prototype = {header={},attributes={}}
    local lua_classe = RuntimeApi.get_classe(lua_prototype.object_name)
    while lua_classe ~= nil do
        for _, lua_attribute in pairs(lua_classe.attributes) do
            local content = nil
            pcall(function()
                content = lua_prototype[lua_attribute.name]
            end)
            local content_type = type(content)
            table.insert(prototype.attributes, self:get_attribute_data(lua_attribute.name, lua_attribute.description, content_type,content))
        end
        lua_classe = RuntimeApi.get_classe(lua_classe.parent)
    end
    return prototype
end

function PropertiesView:get_attribute_data(name, description, type, value)
    local attribute_data = {name=name, description=description, type=type, value=value}
    return attribute_data
end

function PropertiesView:get_lua_prototype(element)
    local lua_prototype = {}
    local attribute = string.gsub(element.type, "-", "_")
    pcall(function()
        lua_prototype = prototypes[attribute][element.name]
    end)
    return lua_prototype
end

