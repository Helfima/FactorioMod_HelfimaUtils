-------------------------------------------------------------------------------
---Class to build rule edition dialog
---@class PropertiesView : Form
PropertiesView = newclass(Form, function(base, classname)
    Form.init(base, classname)
    base.inner_frame = defines.mod.styles.frame.inside_deep
    base.auto_clear = true
    base.mod_menu = true
    base.submenu_enabled = false
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
    --self.parameterLast = string.format("%s_%s",self.classname,"last")
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
    self:update_properties(event)
    self:update_runtime_api(event)
end

---@param event EventModData
function PropertiesView:update_properties(event)
    local content_panel = self:get_tab("properties", "Properties")
    content_panel.clear()
    self:update_properties_menu(event, content_panel)
    self:update_properties_data(event, content_panel)
end

---@param event EventModData
---@param parent LuaGuiElement
function PropertiesView:update_properties_menu(event, parent)
    local content_panel = GuiElement.add(parent, GuiFlowH("menu"))
    content_panel.style.horizontally_stretchable = true
    content_panel.style.bottom_margin = 5

    local left_panel = GuiElement.add(content_panel, GuiFlowH("left"))
    local right_panel = GuiElement.add(content_panel, GuiFlowH("right"))
    right_panel.style.left_margin = 20

    local left_flow = GuiElement.add(left_panel, GuiTable("filters"):column(2))
    left_flow.style.horizontal_spacing = 5
    left_flow.style.vertical_align = "center"

    -- selector
    GuiElement.add(left_flow, GuiLabel("choose-label"):caption("Choose:"))

    local cell_selector = GuiElement.add(left_flow, GuiFlowH("selector"))
    cell_selector.style.horizontal_spacing = 5


    local items = {"item","entity","recipe"}
    local selected = User.get_parameter("type_choosed") or "item"
    GuiElement.add(cell_selector, GuiDropDown(self.classname, "type_choose"):items(items, selected))

    local choose_type = string.format("%s-with-quality", selected)
    local dropdown = GuiElement.add(cell_selector, GuiButtonSprite(self.classname, "element_choose"):choose(choose_type):style(defines.mod.styles.button.select_icon))
    dropdown.style.width = 27
    dropdown.style.height = 27

    -- filter
    GuiElement.add(left_flow, GuiLabel("filter-property-label"):caption("Filter:"))
    local filter_value = User.get_parameter("filter-property")
    local filter_field = GuiElement.add(left_flow, GuiTextField(self.classname, "filter-property", "onchange"):text(filter_value))
    filter_field.style.width = 300
    
    local right_flow = GuiElement.add(right_panel, GuiTable("filters"):column(2))
    right_flow.style.horizontal_spacing = 5
    right_flow.style.vertical_align = "center"

    -- Runtime API
    local runtime_api = Cache.get_data(self.classname, "runtime_api")
    GuiElement.add(right_flow, GuiLabel("runtime_api_label"):caption("API Version:"))
    if runtime_api then
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
    GuiElement.add(right_flow, GuiSwitch(self.classname, "filter_property_switch", "nil"):state(switch_nil):leftLabel("Off"):rightLabel("On"))

    ---difference values
    local switch_nil = "left"
    if User.get_parameter("filter_property_diff") == true then
        switch_nil = "right"
    end
    GuiElement.add(right_flow, GuiLabel("filter-difference-property"):caption("Show differences:"))
    GuiElement.add(right_flow, GuiSwitch(self.classname, "filter_property_switch", "diff"):state(switch_nil):leftLabel("Off"):rightLabel( "On"))

end

---@param event EventModData
---@param parent LuaGuiElement
function PropertiesView:update_properties_data(event, parent)
    local content_panel = GuiElement.add(parent, GuiScroll("content"))
    content_panel.style.horizontally_stretchable = true

    local prototype = self:get_data()

    local table = GuiElement.add(content_panel, GuiTable("item"):column(3):style(defines.mod.styles.table.bordered_gray))

    local sorter = function(t, a, b) return t[b]["name"] > t[a]["name"] end
    for _, attribute in spairs(prototype.header, sorter) do
        local cell_name = GuiElement.add(table, GuiFlowH():tooltip(attribute.description))
        GuiElement.add(cell_name, GuiLabel("content"):caption(attribute.name):style(defines.mod.styles.label.heading_2))
        
        local cell_type = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_type, GuiLabel("content"):caption(attribute.type))
        
        local cell_content = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_content, GuiLabel("content"):caption(attribute.value))
    end

    for _, attribute in spairs(prototype.attributes, sorter) do
        if not(User.get_parameter("filter_property_nil") and attribute.value == nil) then
            
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
            
            local cell_content = GuiElement.add(table, GuiFlowH())
            if attribute.type == "userdata" then
                self:update_attribute_userdata(cell_content, attribute)
            elseif attribute.type == "table" then
                self:update_attribute_table(cell_content, attribute.value)
            elseif attribute.type == "boolean" then
                if attribute.value then
                    GuiElement.add(cell_content, GuiLabel("content"):caption("true"))
                else
                    GuiElement.add(cell_content, GuiLabel("content"):caption("false"))
                end
            else
                GuiElement.add(cell_content, GuiLabel("content"):caption(attribute.value or ""))
            end
        end
    end
end

function PropertiesView:update_attribute_table(parent, content)
    local table = GuiElement.add(parent, GuiTable("item"):column(2):style(defines.mod.styles.table.bordered_green))
    for name, value in pairs(content) do
        local cell_name = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_name, GuiLabel("content"):caption(name))
        local cell_content = GuiElement.add(table, GuiFlowH())

        local content_type = type(value)
        if content_type == "userdata" then
            GuiElement.add(cell_content, GuiLabel("content"):caption(value.object_name))
        elseif content_type == "table" then
            if #content > 0 then
                self:update_attribute_table(cell_content, value)
            else
                GuiElement.add(cell_content, GuiLabel("content"):caption("table"))
            end
        else
            GuiElement.add(cell_content, GuiLabel("content"):caption(value))
        end
    end
end

function PropertiesView:update_attribute_userdata(parent, attribute)
    GuiElement.add(parent, GuiLabel("content"):caption(attribute.value.object_name))
end

---@param event EventModData
function PropertiesView:update_runtime_api(event)
    local content_panel = self:get_tab("runtime_api", "Runtime API")
    content_panel.clear()
    self:update_runtime_api_menu(event, content_panel)
    self:update_runtime_api_data(event, content_panel)
end

---@param event EventModData
---@param parent LuaGuiElement
function PropertiesView:update_runtime_api_menu(event, parent)
    local content_panel = GuiElement.add(parent, GuiFlowV("menu"))
    content_panel.style.horizontally_stretchable = true

    local menu_flow = GuiElement.add(content_panel, GuiTable("filters"):column(2))
    menu_flow.style.horizontal_spacing = 20
    menu_flow.style.vertical_align = "center"

    -- Runtime API
    local runtime_api = Cache.get_data(self.classname, "runtime_api")
    GuiElement.add(menu_flow, GuiLabel("runtime_api_label"):caption("API Version:"))
    GuiElement.add(menu_flow, GuiLabel("runtime_api_version"):caption(runtime_api["application_version"]))

    GuiElement.add(menu_flow, GuiLabel("runtime_api_input"):caption("Input json"))
    GuiElement.add(menu_flow, GuiTextField(self.classname, "change_runtime_api"))

end

---@param event EventModData
---@param parent LuaGuiElement
function PropertiesView:update_runtime_api_data(event, parent)
    local content_panel = GuiElement.add(parent, GuiScroll("content"))
    content_panel.style.horizontally_stretchable = true

end

-------------------------------------------------------------------------------
---On event
---@param event EventModData
function PropertiesView:on_event(event)

    if event.action == "type_choose" then
        local dropdown = event.element
        local type_choosed = dropdown.get_item(dropdown.selected_index)
        User.set_parameter("type_choosed", type_choosed)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "element_choose" then
        local element_type = User.get_parameter("type_choosed") or "item"
        local element_value = event.element.elem_value
        local element_choosed = {type=element_type, name=element_value.name, quality=element_value.quality }
        User.set_parameter("element_choosed", element_choosed)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "change_runtime_api" then
        local json_string = event.element.text
        local api = helpers.json_to_table(json_string)
        if api ~= nil then
            Cache.set_data(self.classname, "runtime_api", api)
        end
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "filter_property_switch" then
        local switch_nil = event.element.switch_state == "right"
        local parameter_name = string.format("filter_property_%s", event.item1)
        User.set_parameter(parameter_name, switch_nil)
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end
end

function PropertiesView:get_data()
    local element_choosed = User.get_parameter("element_choosed") or {}
    local prototype = {header={},attributes={}}
    table.insert(prototype.header, self:get_attribute_data("type", nil, "string", element_choosed.type))
    table.insert(prototype.header, self:get_attribute_data("name", nil, "string", element_choosed.name))
    table.insert(prototype.header, self:get_attribute_data("quality", nil, "string", element_choosed.quality))

    local lua_prototype= self:get_lua_prototype(element_choosed)
    table.insert(prototype.header, self:get_attribute_data("lua_prototype", nil, "string", lua_prototype.object_name))
    local lua_attributes = self:get_classe_attributes(lua_prototype.object_name)
    for _, lua_attribute in pairs(lua_attributes) do
        local content = lua_prototype[lua_attribute.name]
        local content_type = type(content)
        table.insert(prototype.attributes, self:get_attribute_data(lua_attribute.name, lua_attribute.description, content_type,content))
    end
    return prototype
end

function PropertiesView:get_attribute_data(name, description, type, value)
    local attribute_data = {name=name, description=description, type=type, value=value}
    return attribute_data
end

function PropertiesView:get_lua_prototype(element)
    local lua_prototype = prototypes[element.type][element.name]
    return lua_prototype
end

---Return attributes of classe
---@param object_name any
---@return unknown
function PropertiesView:get_classe_attributes(object_name)
    local runtime_api = Cache.get_data(self.classname, "runtime_api")
    for _, value in pairs(runtime_api["classes"]) do
        if value.name == object_name then
            return value.attributes
        end
    end
    return {}
end
