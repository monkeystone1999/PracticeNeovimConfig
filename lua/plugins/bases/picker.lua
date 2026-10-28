-- <leader>ws : Workspace 목록 floating box
local ws = require("workspace")
local ui = require("workspace.ui")

local M = {}

function M.add()
    vim.ui.input({ prompt = "Workspace path: ", default = vim.fn.getcwd(), completion = "dir" }, function(path)
        if path and path ~= "" then ws.open(path) end
    end)
end

function M.open()
    local tabs, cur = ws.list(), vim.api.nvim_get_current_tabpage()
    local names, wide, at = {}, 0, 1
    for i, tab in ipairs(tabs) do
        names[i] = ws.name(tab)
        wide = math.max(wide, vim.fn.strdisplaywidth(names[i]))
        if tab == cur then at = i end
    end

    local lines = {}
    for i, tab in ipairs(tabs) do
        local pad = (" "):rep(wide - vim.fn.strdisplaywidth(names[i]))
        lines[i] = (" %s %s%s  %s "):format(
            tab == cur and "●" or " ", names[i], pad, vim.fn.fnamemodify(ws.root(tab), ":~")
        )
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    local win = ui.float(buf, { title = " Workspaces ", fit = true, cursorline = true })
    vim.api.nvim_win_set_cursor(win, { at, 0 })

    local function selected() return tabs[vim.api.nvim_win_get_cursor(win)[1]] end
    local function close()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end
    local function key(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true }) end

    key("<CR>", function()
        local tab = selected()
        close()
        if tab then vim.api.nvim_set_current_tabpage(tab) end
    end)
    key("a", function()
        close(); M.add()
    end)
    key("d", function()
        local tab = selected()
        close()
        if tab then ws.close(tab) end
        M.open()
    end)
    key("q", close)
    key("<Esc>", close)

    vim.api.nvim_create_autocmd("BufLeave", { buffer = buf, once = true, callback = function() vim.schedule(close) end })
end

function M.setup()
    vim.api.nvim_create_user_command("WsList", M.open, {})
    vim.api.nvim_create_user_command("WsOpen", function(c) ws.open(c.args) end, { nargs = 1, complete = "dir" })
end

return M
