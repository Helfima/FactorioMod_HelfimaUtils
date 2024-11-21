require "__HelfimaLib__.lib_require"
require "core.defines"
require("views.Views")

local handler = require("event_handler")

handler.add_lib(Dispatcher)

Form.views["PropertiesView"] = PropertiesView("PropertiesView")
