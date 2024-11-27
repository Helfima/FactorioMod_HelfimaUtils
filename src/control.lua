require "__HelfimaLib__.lib_require"
require "core.defines"
require("views.Views")

---@type RuntimeApi
RuntimeApi = require "__HelfimaUtils__.scripts.RuntimeApi"

local handler = require("event_handler")

handler.add_lib(Dispatcher)
handler.add_lib(RuntimeApi)

Form.views["PropertiesView"] = PropertiesView("PropertiesView")
Form.views["RuntimaApiView"] = RuntimaApiView("RuntimaApiView")

local command_help = string.format("%s commands", defines.mod.mod_name)
Dispatcher:start_command(defines.mod.tag, command_help)

source_api = require("scripts.SourceApi")