-------------------------------------------------------------------------------
---Description of the module.
---@class RuntimeApi
local RuntimeApi = {
    ---single-line comment
    classname = "RuntimeApi"
}

local sections = {}
sections["classes"] = {name="classes", localised_name="Classes"}
sections["events"] = {name="events", localised_name="Events"}
sections["concepts"] = {name="concepts", localised_name="Concepts"}
sections["defines"] = {name="defines", localised_name="Defines"}
sections["global_objects"] = {name="global_objects", localised_name="Global Objects"}
sections["global_functions"] = {name="global_functions", localised_name="Global Functions"}

local history = {}

-------------------------------------------------------------------------------
---Return Runtime API
---@return any
function RuntimeApi.get_api()
    return Cache.get_data(RuntimeApi.classname, "runtime_api")
end

-------------------------------------------------------------------------------
---Set Runtime API
---@param json string | table
function RuntimeApi.set_api(json)
    local api = json
    if type(json) == "string" then
        api = helpers.json_to_table(json)
    end
    --helpers.write_file("api.lua", serpent.block(api))
    if api ~= nil then
        Cache.set_data(RuntimeApi.classname, "runtime_api", api)
    end
end

-------------------------------------------------------------------------------
---Return Runtime API
---@return any
function RuntimeApi.get_sections()
    return sections
end

-------------------------------------------------------------------------------
---Return Runtime API
---@param section_name string
---@param expand? boolean
---@return any
function RuntimeApi.expand_section(section_name, expand)
    local sections = RuntimeApi.get_sections()
    for _, section in pairs(sections) do
        if section.name == section_name then
            if expand ~= nil then
                section.expand = expand
            else
                section.expand = true
            end
        else
            section.expand = false
        end
    end
    return sections
end

-------------------------------------------------------------------------------
---Return Runtime API
---@return any
function RuntimeApi.get_history()
    return history
end

-------------------------------------------------------------------------------
---Return Runtime API
---@return any
function RuntimeApi.set_history(section, sub_section)
    history.section = section
    history.sub_section = sub_section
    RuntimeApi.expand_section(section)
    return history
end

---Return classe
---@param object_name string
---@return any
function RuntimeApi.get_classe(object_name)
    local runtime_api = Cache.get_data(RuntimeApi.classname, "runtime_api")
    if runtime_api ~= nil then
        for _, value in pairs(runtime_api["classes"]) do
            if value.name == object_name then
                return value
            end
        end
    end
    return nil
end

---Return attributes of classe
---@param object_name string
---@return table
function RuntimeApi.get_classe_attributes(object_name)
    local runtime_api = Cache.get_data(RuntimeApi.classname, "runtime_api")
    for _, value in pairs(runtime_api["classes"]) do
        if value.name == object_name then
            return value.attributes
        end
    end
    return {}
end

---comment
---@param data ConfigurationChangedData
function RuntimeApi.on_configuration_changed(data)
end

function RuntimeApi.on_init()
    local api = RuntimeApi.get_api()
    if api == nil then
        RuntimeApi.set_api(source_api)
    end
end

return RuntimeApi
