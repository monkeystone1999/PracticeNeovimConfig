local workspace = require("bases.workspaces")
local terminal = require("bases.terminal")

local M = {}

function M.get_list()
    return { workspace.get_list(), terminal.get_list() }
end

function M.setup()
    workspace.setup()
    terminal.setup()
end

return M
