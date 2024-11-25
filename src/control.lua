require "__HelfimaLib__.lib_require"
require "core.defines"
require("views.Views")

---@type RuntimeApi
RuntimeApi = require "__HelfimaUtils__.scripts.RuntimeApi"

local handler = require("event_handler")

handler.add_lib(Dispatcher)

Form.views["PropertiesView"] = PropertiesView("PropertiesView")
Form.views["RuntimaApiView"] = RuntimaApiView("RuntimaApiView")
