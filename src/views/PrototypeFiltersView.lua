-------------------------------------------------------------------------------
---Class to build Prototype Filters View
---@class PrototypeFiltersView : Form
PrototypeFiltersView = newclass(Form, function(base, classname)
    Form.init(base, classname)
    base.auto_clear = true
    base.mod_menu = true
    base.submenu_enabled = true
end)

PrototypeFilters = require "__HelfimaUtils__.scripts.PrototypeFilters"

-------------------------------------------------------------------------------
---On Style
---@param styles table
---@param width_main number
---@param height_main number
function PrototypeFiltersView:on_style(styles, width_main, height_main)
    styles.flow_panel = {
        width = width_main * 0.8,
        height = height_main * 0.8
    }
end

-------------------------------------------------------------------------------
---On initialization
function PrototypeFiltersView:on_init()
    self.panel_caption = { "", { "HelfimaUtils.prototype-filters-title" }, " ", script.active_mods["HelfimaUtils"] }
end

-------------------------------------------------------------------------------
---For Bind Dispatcher Event
function PrototypeFiltersView:on_bind()

end

-------------------------------------------------------------------------------
---Get Button Sprites
---@return string,string
function PrototypeFiltersView:get_button_sprites()
    return defines.sprites.database_test.white, defines.sprites.database_test.black
end

-------------------------------------------------------------------------------
---On before open
---@param event EventModData
function PrototypeFiltersView:on_open_before(event)
end

-------------------------------------------------------------------------------
---On Update
---@param event EventModData
function PrototypeFiltersView:on_update(event)
    self:update_top_menu(event)
    self:update_data(event)
    self:update_result(event)
end

local filter_types = PrototypeFilters.get_filters()
local modes = PrototypeFilters.get_modes()
local inverts = PrototypeFilters.get_inverts()
local comparisons = PrototypeFilters.get_comparisons()
local concept = nil
local textbox_filters = nil

local prototype_filter_type = "ItemPrototypeFilter"
local prototype_filter = {
    mode = "or",
    invert = "false"
}
---@param event EventModData
function PrototypeFiltersView:update_result(event)
    local content_panel = self:get_scroll_panel("result")
    content_panel.clear()

    local table_filters = GuiElement.add(content_panel, GuiTable("table-filters"):column(2))
    table_filters.vertical_centering = false
    table_filters.style.padding = 5
    GuiElement.add(table_filters, GuiLabel("col-1"):caption("Filters"))
    GuiElement.add(table_filters, GuiLabel("col-2"):caption("Elements"))

    local prototype_filters = User.get_parameter("prototype_filters") or {}
    local caption = self:table_to_string(prototype_filters)
    textbox_filters = GuiElement.add(table_filters, GuiTextBox("filters"):text(caption))
    textbox_filters.style.size = {550,400}

    local cell_elements = GuiElement.add(table_filters, GuiScroll("table-elements"))
    cell_elements.style.size = {775,400}
    local table_elements = GuiElement.add(cell_elements, GuiTable("table-elements"):column(20))
    local elements = PrototypeFilters.get_elements(prototype_filter_type, prototype_filters)
    local filter = PrototypeFilters.get_filter_type(prototype_filter_type)
    for key,element in pairs(elements) do
        local button = GuiElement.add(table_elements, GuiButtonSelectSprite("nothing"):choose(filter.type:lower(), element.name))
        button.locked = true
    end
end

-------------------------------------------------------------------------------
---Table to string
---@param value table
---@return string
function PrototypeFiltersView:table_to_string(value)
  local string_value = serpent.line(value)
  string_value = string.gsub(string_value, "},", "},\n")
  return string_value
end

---@param event EventModData
function PrototypeFiltersView:update_data(event)
    concept = PrototypeFilters.get_concept(prototype_filter_type)
    local filters = PrototypeFilters.get_concept_filter(concept)
    table.sort(filters)

    local content_panel = self:get_flow_panel("filter")
    content_panel.clear()
    content_panel.style.padding = 5

    local filter_table = GuiElement.add(content_panel, GuiTable("table-filter"):column(5))
    filter_table.vertical_centering = false
    filter_table.style.padding = 5
    GuiElement.add(filter_table, GuiLabel("col-1"):caption("Mode"))
    GuiElement.add(filter_table, GuiLabel("col-2"):caption("Invert"))
    GuiElement.add(filter_table, GuiLabel("col-3"):caption("Filter"))
    GuiElement.add(filter_table, GuiLabel("col-4"):caption("Options"))
    GuiElement.add(filter_table, GuiLabel("col-5"):caption("Info"))

    -- mode col
    local button_mode = GuiElement.add(filter_table, GuiDropDown(self.classname, "change-filter", "mode"):items(modes, prototype_filter.mode))
    button_mode.style.width = 80
    -- invert col
    local button_invert = GuiElement.add(filter_table, GuiDropDown(self.classname, "change-filter", "invert"):items(inverts, prototype_filter.invert))
    button_invert.style.width = 80
    -- filter col
    prototype_filter.filter = prototype_filter.filter or filters[1]
    GuiElement.add(filter_table, GuiDropDown(self.classname, "change-filter", "filter"):items(filters, prototype_filter.filter))
    -- options col
    local options = PrototypeFilters.get_concept_options(concept, prototype_filter.filter)
    local cell_options = GuiElement.add(filter_table, GuiTable("table-options"):column(2))
    if options ~= nil then
        for index, option in pairs(options) do
            self:update_option(cell_options, option, index)
        end
    else
        GuiElement.add(filter_table, GuiLabel("option-none"):caption("None"))
    end
    -- data col
    local cell_info = GuiElement.add(filter_table, GuiFlowV())
    if options ~= nil then
        GuiElement.add(cell_info, GuiTree("expand-options"):caption("options..."):source(options):font_color(defines.color.blue.deep_sky_blue))
    end

    local cell_actions = GuiElement.add(content_panel, GuiFlowH())
    cell_actions.style.padding = 5

    GuiElement.add(cell_actions, GuiButton(self.classname, "new-filters"):caption("New filters"))
    GuiElement.add(cell_actions, GuiButton(self.classname, "save-filters"):caption("Save filters"))
    GuiElement.add(cell_actions, GuiButton(self.classname, "add-filter"):caption("Add filter"))
end

---Update option
---@param parent LuaGuiElement
---@param option any
function PrototypeFiltersView:update_option(parent, option, index)
    GuiElement.add(parent, GuiLabel("option-label", index):caption(option.name):tooltip(option.description))
    
    local cell_value = GuiElement.add(parent, GuiFlowH())
    local option_value = prototype_filter[option.name]
    if option.type == "double" or option.type == "uint8" or option.type == "uint32" then
        local text_field = GuiElement.add(cell_value, GuiTextField(self.classname, "change-option", option.name, index):text(option_value or 0))
        text_field.style.width = 100
    else
        local text_field = GuiElement.add(cell_value, GuiTextField(self.classname, "change-option", option.name, index):text(option_value))
        text_field.style.width = 200
    end
    if option.name == "mask" then
        local collision_layers = {"choose..."}
        for _, prototype in pairs(prototypes.collision_layer) do
            table.insert(collision_layers, prototype.name)
        end
        local dropdown = GuiElement.add(cell_value, GuiDropDown(self.classname, "change-option-dropdown", "mask", index):items(collision_layers))
    elseif option.name == "mask_mode" then
        local mask_modes = {"choose..."}
        for _, mask_mode in pairs(option.type.options) do
            table.insert(mask_modes, mask_mode.value)
        end
        local dropdown = GuiElement.add(cell_value, GuiDropDown(self.classname, "change-option-dropdown", "mask_mode", index):items(mask_modes))
    elseif option.type == "ComparatorString" then
        local dropdown = GuiElement.add(cell_value, GuiDropDown(self.classname, "change-option-dropdown", "comparison", index):items(comparisons))
        dropdown.style.width = 100
    end
end

---@param event EventModData
function PrototypeFiltersView:update_top_menu(event)
    local flow_panel, content_panel, submenu_panel, menu_panel = self:get_panel()
    submenu_panel.style.height = 0
    
    submenu_panel.clear()

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


    local items = {}
    local filter_selected = "Item"
    for _, filter in pairs(filter_types) do
        table.insert(items, filter.type)
        if filter.filter == prototype_filter_type then
            filter_selected = filter.type
        end
    end
    GuiElement.add(cell_selector, GuiDropDown(self.classname, "filter-choose"):items(items, filter_selected))

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
end

-------------------------------------------------------------------------------
---On event
---@param event EventModData
function PrototypeFiltersView:on_event(event)
    if event.action == "filter-choose" then
        local selected_index = event.element.selected_index
        local selected_value = event.element.items[selected_index]
        for _, filter_type in pairs(filter_types) do
            if filter_type.type == selected_value then
                prototype_filter_type = filter_type.filter
            end
        end
        prototype_filter = {
            mode = "or",
            invert = "false"
        }
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "change-filter" then
        local selected_index = event.element.selected_index
        local selected_value = event.element.items[selected_index]
        local attr = event.item1
        prototype_filter[attr] = selected_value
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "change-option-dropdown" then
        local selected_index = event.element.selected_index
        local selected_value = event.element.items[selected_index]
        local attr = event.item1
        prototype_filter[attr] = selected_value
        Dispatcher:send(defines.mod.events.on_gui_update, nil, self.classname)
    end

    if event.action == "new-filters" then
        User.set_parameter("prototype_filters", nil)
        self:update_result(event)
    end

    if event.action == "save-filters" then
        local value = textbox_filters.text
        local check = false
        check, prototype_filters = serpent.load(value)
        User.set_parameter("prototype_filters", prototype_filters)
        self:update_result(event)
    end

    if event.action == "add-filter" then
        local prototype_filters = User.get_parameter("prototype_filters") or {}
        table.insert(prototype_filters, table.deepcopy(prototype_filter))
        User.set_parameter("prototype_filters", prototype_filters)
        self:update_result(event)
    end
end