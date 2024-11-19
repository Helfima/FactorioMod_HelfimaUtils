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
    Dispatcher:send(defines.mod.events.on_gui_update, nil, MapOptionsView.classname)
end

-------------------------------------------------------------------------------
---Get Button Sprites
---@return string,string
function PropertiesView:get_button_sprites()
  return defines.sprites.database_schema.white, defines.sprites.database_schema.black
end

-------------------------------------------------------------------------------
---On Update
---@param event EventModData
function PropertiesView:on_update(event)
    self:update_menu(event)
    self:update_data(event)
end

---@param event EventModData
function PropertiesView:update_menu(event)
    local flow_panel, content_panel, submenu_panel, menu_panel = self:get_panel()
    submenu_panel.style.height = 0
    local menu_flow = GuiElement.add(submenu_panel, GuiTable("filters"):column(3))
    menu_flow.style.horizontal_spacing = 20
    menu_flow.style.vertical_align = "center"

    local selector_panel = GuiElement.add(menu_flow, GuiFlowH("selector"))
    selector_panel.style.horizontal_spacing = 5

    local items = {"item","entity","recipe"}
    local selected = User.get_parameter("type_choosed") or "item"
    GuiElement.add(selector_panel, GuiDropDown(self.classname, "type_choose"):items(items, selected))

    local choose_type = string.format("%s-with-quality", selected)
    local dropdown = GuiElement.add(selector_panel, GuiButtonSprite(self.classname, "element_choose"):choose(choose_type):style(defines.mod.styles.button.select_icon))
    dropdown.style.width = 27
    dropdown.style.height = 27

    -- Runtime API
    local runtime_api = Cache.get_data(self.classname, "runtime_api")
    local runtime_api_panel = GuiElement.add(menu_flow, GuiFlowH())
    if runtime_api then
        GuiElement.add(runtime_api_panel, GuiLabel("runtime_api_label"):caption(" API Version: "))
        GuiElement.add(runtime_api_panel, GuiLabel("runtime_api_version"):caption(runtime_api["application_version"]))
    end
    local json_string = GuiElement.add(menu_flow, GuiTextField(self.classname, "change_runtime_api"))

    ---nil values
    local cell_filter_nil = GuiElement.add(menu_flow, GuiFlowH())
    cell_filter_nil.style.horizontal_spacing = 5
    local switch_nil = "left"
    if User.get_parameter("filter_property_nil") == true then
        switch_nil = "right"
    end
    GuiElement.add(cell_filter_nil, GuiLabel("filter-nil-property"):caption("Hide nil values:"))
    local filter_switch = GuiElement.add(cell_filter_nil, GuiSwitch(self.classname, "filter_property_switch", "nil"):state(switch_nil):leftLabel("Off"):rightLabel("On"))
    
    ---difference values
    local cell_filter_diff = GuiElement.add(menu_flow, GuiFlowH())
    cell_filter_diff.style.horizontal_spacing = 5
    local switch_nil = "left"
    if User.get_parameter("filter_property_diff") == true then
        switch_nil = "right"
    end
    GuiElement.add(cell_filter_diff, GuiLabel("filter-difference-property"):caption("Show differences:"))
    local filter_switch = GuiElement.add(cell_filter_diff, GuiSwitch(self.classname, "filter_property_switch", "diff"):state(switch_nil):leftLabel("Off"):rightLabel( "On"))

    -- filter
    local cell_filter = GuiElement.add(menu_flow, GuiFlowH())
    cell_filter.style.horizontal_spacing = 5
    GuiElement.add(cell_filter, GuiLabel("filter-property-label"):caption("Filter:"))
    local filter_value = User.get_parameter("filter-property")
    local filter_field = GuiElement.add(cell_filter, GuiTextField(self.classname, "filter-property", "onchange"):text(filter_value))
    filter_field.style.width = 300

end

---@param event EventModData
function PropertiesView:update_data(event)
    local content_panel = self:get_scroll_panel("data")
    content_panel.clear()

    local prototype = self:get_data()

    local table = GuiElement.add(content_panel, GuiTable("item"):column(3):style(defines.mod.styles.table.bordered_gray))

    local sorter = function(t, a, b) return t[b]["name"] > t[a]["name"] end
    for _, attribute in spairs(prototype.header, sorter) do
        local cell_name = GuiElement.add(table, GuiFlowH():tooltip(attribute.description))
        GuiElement.add(cell_name, GuiLabel("content"):caption(attribute.name))
        
        local cell_type = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_type, GuiLabel("content"):caption(attribute.type))
        
        local cell_content = GuiElement.add(table, GuiFlowH())
        GuiElement.add(cell_content, GuiLabel("content"):caption(attribute.value))
    end

    for _, attribute in spairs(prototype.attributes, sorter) do
        if not(User.get_parameter("filter_property_nil") and attribute.value == nil) then
            
            local cell_name = GuiElement.add(table, GuiFlowH())
            GuiElement.add(cell_name, GuiLabel("content"):caption(attribute.name):tooltip(attribute.description))
            
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
    table.insert(prototype.attributes, self:get_attribute_data("lua_prototype", nil, lua_prototype.object_name))
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
