---
---Description of the module.
---@class Blueprint
local Blueprint = {
  ---single-line comment
  classname = "HMBlueprint",
  layouts_tiles_store= "layouts_tiles"
}

---comment
---@param item_stack LuaItemStack
---@return table
function Blueprint.get_entity_prototypes(item_stack)
    local prototypes = {}
    if item_stack.is_blueprint then
        local entities = item_stack.get_blueprint_entities()
        prototypes = Blueprint.get_entity_names(entities)
    end
    return prototypes
end

-------------------------------------------------------------------------------
---Return entity prototype
---@param name string
---@return LuaEntityPrototype
function Blueprint.get_entity_prototype(name)
  if name == nil then return nil end
  return game.entity_prototypes[name]
end

function Blueprint.get_entity_names(elements)
    local list = {}
    if elements then
        for key, element in pairs(elements) do
            local name = element.name
            if not(list[name]) then
                list[name] = {name=name}
            end
        end
    end

    for name, item in pairs(list) do
        local lua_item = Blueprint.get_entity_prototype(name)
        item.lua_prototype = lua_item
    end
    return list
end

---comment
---@param item_stack LuaItemStack
---@return table
function Blueprint.get_tile_prototypes(item_stack)
    local prototypes = {}
    if item_stack.is_blueprint then
        local tiles = item_stack.get_blueprint_tiles()
        prototypes = Blueprint.get_tile_names(tiles)
    end
    return prototypes
end

-------------------------------------------------------------------------------
---Return entity prototype
---@param name string
---@return LuaEntityPrototype
function Blueprint.get_item_prototype(name)
  if name == nil then return nil end
  return game.item_prototypes[name]
end

function Blueprint.get_tile_names(elements)
    local list = {}
    if elements then
        for key, element in pairs(elements) do
            local name = element.name
            if not(list[name]) then
                list[name] = {name=name}
            end
        end
    end

    for name, item in pairs(list) do
        local lua_item = Blueprint.get_item_prototype(name)
        item.lua_prototype = lua_item
    end
    return list
end

---comment
---@param item_stack LuaItemStack
---@param replacements any
function Blueprint.apply_replacements(item_stack, replacements)
    if item_stack.is_blueprint then
        local entities = item_stack.get_blueprint_entities()
        if entities ~= nil then
            for _, entity in pairs(entities) do
                if replacements.entities[entity.name] then
                    entity.name = replacements.entities[entity.name]
                end
            end
            item_stack.set_blueprint_entities(entities)
        end
        
        local tiles = item_stack.get_blueprint_tiles()
        if tiles ~= nil then
            for _, tile in pairs(tiles) do
                if replacements.tiles[tile.name] then
                    tile.name = replacements.tiles[tile.name]
                end
            end
            item_stack.set_blueprint_tiles(tiles)
        end
    end
end

function math.round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

---comment
---@param tiles table
---@param tile_name string
---@param entity BlueprintEntity
function Blueprint.append_under_tiles(tiles, tile_name, entity)
    local layout_tiles = Blueprint.layout_tiles(entity.name, entity.direction or 0)
    if layout_tiles ~= nil then
        for xrow, layout_tile in pairs(layout_tiles) do
            for yrow, _ in pairs(layout_tile) do
                local tile_position = {x = xrow, y = yrow}
                local offset = Blueprint.position_add(entity.position, {x=-0.5,y=-0.5})
                tile_position = Blueprint.position_add(tile_position, offset)
                tile_position = Blueprint.position_round(tile_position)
                local tile = {
                    name=tile_name,
                    position=tile_position
                }
                table.insert(tiles, tile)
            end
        end
    end
end

---Save layouts tiles in the cache
---@param entity_name string
---@param direction integer
function Blueprint.save_layout_tiles(entity_name, direction, layout_tiles)
    local layouts_tiles = Cache.get_data(Blueprint.classname, Blueprint.layouts_tiles_store)
    if layouts_tiles == nil then layouts_tiles = Cache.set_data(Blueprint.classname, Blueprint.layouts_tiles_store, {}) end
    if layouts_tiles[entity_name] == nil then layouts_tiles[entity_name] = {} end
    layouts_tiles[entity_name][direction] = layout_tiles
end

---Find layouts tiles from the cache
---@param entity_name string
---@param direction integer
---@return {[integer]:{[integer]: {x:number,y:number}}} | nil
function Blueprint.find_layout_tiles(entity_name, direction)
    local layouts_tiles = Cache.get_data(Blueprint.classname, Blueprint.layouts_tiles_store)
    if layouts_tiles ~= nil and layouts_tiles[entity_name] ~= nil and layouts_tiles[entity_name][direction] ~= nil then
        return layouts_tiles[entity_name][direction]
    end
    return nil
end

---Return tiles layout for a entity
---@param entity_name string
---@param direction integer
---@param offset? Position
---@return {[integer]:{[integer]: {x:number,y:number}}}
function Blueprint.layout_tiles(entity_name, direction, offset)
    local layout_tiles = Blueprint.find_layout_tiles(entity_name, direction)
    if layout_tiles ~= nil then
        return layout_tiles
    end

    layout_tiles = {}
    local lua_prototype = Blueprint.get_entity_prototype(entity_name)
    local tile_width = lua_prototype.tile_width - 1
    local tile_height = lua_prototype.tile_height - 1
    
    for x = 0, tile_width, 1 do
        for y = 0, tile_height, 1 do
            local tile_position = {
                x = x - tile_width/2,
                y = y - tile_height/2
            }
            tile_position = Blueprint.position_rotate(tile_position, direction or 0)
            tile_position = Blueprint.position_round(tile_position)
            if layout_tiles[tile_position.x] == nil then
                layout_tiles[tile_position.x] = {}
            end
            layout_tiles[tile_position.x][tile_position.y] = true
        end
    end

    return layout_tiles
end

---Return box of tiles layout
---@param layout_tiles {[integer]:{[integer]: {x:integer,y:integer}}}
---@return BoundingBox
function Blueprint.layout_box(layout_tiles)
    local box = {left_top = {x = 0, y = 0}, right_bottom = {x = 0, y = 0}}
    if layout_tiles ~= nil then
        for xrow, layout_tile in pairs(layout_tiles) do
            for yrow, _ in pairs(layout_tile) do
                if xrow < box.left_top.x then
                    box.left_top.x = xrow
                end
                if xrow > box.right_bottom.x then
                    box.right_bottom.x = xrow
                end
                if yrow < box.left_top.y then
                    box.left_top.y = yrow
                end
                if yrow > box.right_bottom.y then
                    box.right_bottom.y = yrow
                end
            end
        end
    end
    return box
end

function Blueprint.position_round(position)
    return {
        x = math.ceil(position.x),
        y = math.ceil(position.y)
    }
end

function Blueprint.position_add(position1, position2)
    return {
        x = position1.x + position2.x,
        y = position1.y + position2.y
    }
end

function Blueprint.position_add(position1, position2)
    return {
        x = position1.x + position2.x,
        y = position1.y + position2.y
    }
end

function Blueprint.position_rotate(position, direction)
    local arc = math.pi/4
    local angle = direction * arc
    local cos = math.cos(angle)
    local sin = math.sin(angle)

    local x1 = position.x * cos - position.y * sin
    local y1 = position.x * sin + position.y * cos

    return {
        x=x1,
        y=y1
    }
end

---comment
---@param item_stack LuaItemStack
---@param tile_name string
function Blueprint.apply_tile(item_stack, tile_name)
    if item_stack.is_blueprint then
        local tiles = {}
        local entities = item_stack.get_blueprint_entities()
        for _, entity in pairs(entities) do
            Blueprint.append_under_tiles(tiles, tile_name, entity)
        end
        item_stack.set_blueprint_tiles(tiles)
    end
end

---Convert direction to string
---@param direction int
---@return string
function Blueprint.direction_to_string(direction)
    for key, value in pairs(defines.direction) do
        if direction == value then
            return key
        end
    end
    return "north"
end

---Convert direction to int
---@param direction string
---@return int
function Blueprint.direction_to_int(direction)
    local index = 0
    for key, value in pairs(defines.direction) do
        if direction == key then
            return value
        end
        index = index + 1
    end
    return 0
end

return Blueprint