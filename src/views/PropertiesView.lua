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
    local selector_panel = GuiElement.add(submenu_panel, GuiFlowH("selector"))

    local items = {"item","entity"}
    local selected = User.get_parameter("type_choosed") or "item"
    GuiElement.add(submenu_panel, GuiDropDown(self.classname, "type_choose"):items(items, selected))

    local dropdown = GuiElement.add(submenu_panel, GuiButtonSprite(self.classname, "element_choose"):choose(selected):style(defines.mod.styles.button.select_icon))
    dropdown.style.width = 27
    dropdown.style.height = 27
end

---@param event EventModData
function PropertiesView:update_data(event)
    local flow_panel, content_panel, submenu_panel, menu_panel = self:get_panel()
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
end

