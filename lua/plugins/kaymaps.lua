local ws = require("workspace")
local picker = require("workspace.picker")
local shell = require("workspace.shell")

local M = {}

function M.setup()
    local function map(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { desc = "workspace: " .. desc })
    end

    -- Workspace
    map("<leader>ws", picker.open, "list")
    map("<leader>wa", picker.add, "add")

    -- Shell / 빌드 (모두 Workspace 위치 + .env 기준)
    map("<leader>wt", shell.toggle, "shell")
    map("<leader>wm", function() shell.run("make") end, "make")
    map("<leader>wl", shell.rerun, "rerun last")
    map("<leader>wr", function()
        vim.ui.input({ prompt = "run: ", default = ws.get().last or "", completion = "shellcmd" }, function(cmd)
            if cmd and cmd ~= "" then shell.run(cmd) end
        end)
    end, "run")

    -- Workspace 내 buffer
    map("]b", function() ws.cycle(1) end, "next buffer")
    map("[b", function() ws.cycle(-1) end, "prev buffer")
    map("<leader>bd", ws.close_buf, "close buffer")
    for i = 1, 9 do
        map("<leader>" .. i, function() ws.go(i) end, "buffer " .. i)
    end
end

return M
