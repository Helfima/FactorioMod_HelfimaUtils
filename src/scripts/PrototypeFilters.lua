-------------------------------------------------------------------------------
---Description of the module.
---@class PrototypeFilters
local PrototypeFilters = {
    ---single-line comment
    classname = "PrototypeFilters"
}

local filters = {}
filters["ItemPrototypeFilter"] = {type="Item", method = "get_item_filtered", filter = "ItemPrototypeFilter"}
filters["EntityPrototypeFilter"] = {type="Entity", method = "get_entity_filtered", filter = "EntityPrototypeFilter"}
filters["RecipePrototypeFilter"] = {type="Recipe", method = "get_recipe_filtered", filter = "RecipePrototypeFilter"}

-------------------------------------------------------------------------------
---Return Filters
---@return any
function PrototypeFilters.get_filters()
    return filters
end

-------------------------------------------------------------------------------
---Return Filter
---@param prototype_filter_type string
---@return any
function PrototypeFilters.get_filter_type(prototype_filter_type)
    return filters[prototype_filter_type]
end

-------------------------------------------------------------------------------
---Get modes
---@return table
function PrototypeFilters.get_modes()
  local modes = {"or","and"}
  return modes
end

-------------------------------------------------------------------------------
---Get inverts
---@return table
function PrototypeFilters.get_inverts()
  local modes = {"false","true"}
  return modes
end

-------------------------------------------------------------------------------
---Get comparison
---@return table
function PrototypeFilters.get_comparisons()
  local modes = {"<", ">", "=", "≥", "≤", "≠"}
  return modes
end

-------------------------------------------------------------------------------
---Return concept
---@param prototype_filter_type string
---@return any
function PrototypeFilters.get_concept(prototype_filter_type)
    local runtime_api = RuntimeApi.get_api()
    for _, concept in pairs(runtime_api["concepts"]) do
        if concept.name == prototype_filter_type then
            return concept
        end
    end
    return nil
end

-------------------------------------------------------------------------------
---Return filter names
---@param concept any
---@return any
function PrototypeFilters.get_concept_filter(concept)
    local filter_names = {}
    local options = concept.type.parameters[1].type.options
    for _, option in pairs(options) do
        table.insert(filter_names, option.value)
    end
    return filter_names
end

-------------------------------------------------------------------------------
---Return filter names
---@param concept any
---@param filter string
---@return any
function PrototypeFilters.get_concept_options(concept, filter)
    local variant_parameter_groups = concept.type.variant_parameter_groups
    for _, variant_parameter_group in pairs(variant_parameter_groups) do
        if variant_parameter_group.name == filter then
            return variant_parameter_group.parameters
        end
    end
    return nil
end

-------------------------------------------------------------------------------
---Return filter names
---@param prototype_filter_type string
---@param filters any
---@return any
function PrototypeFilters.get_elements(prototype_filter_type, filters)
    local filter = PrototypeFilters.get_filter_type(prototype_filter_type)
    if filter ~= nil then
        local method = filter.method
        local elements = prototypes[method](filters)
        return elements
    end
    return {}
end

return PrototypeFilters