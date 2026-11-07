local M = {}

local wc = require("custom.bases.workspace")


local function get_win_opts()
    local width = math.floor(vim.o.columns * 0.5)
    local height = math.floor(vim.o.lines * 0.4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    return {
        relative = "editor",
        width = math.max(width, 40),
        height = math.max(height, 8),
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Workspace List",
        title_pos = "center",
        footer = "s:Save Current, a:Add, d:Delete, r:Rename, Enter:Select",
        footer_pos = "center"
    }
end


local buf = nil
local win = nil

function M.setup()
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].filetype = "workspace_list"

    local list_view = {}
    local function render()
        list_view = {}
        local lines = {}
        local current_cwd = vim.fn.getcwd(0)

        for name, path in pairs(wc.get_list()) do
            table.insert(list_view, name)
            local is_active = (path == current_cwd) and " *(active)*" or ""
            table.insert(lines, string.format(" • %-15s : %s%s", name, path, is_active))
        end
        if #lines == 0 then
            lines = { " (등록된 워크스페이스가 없습니다. 's' 를 눌러 현재 상태를 저장하세요)" }
        end
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
    end
    render()
    vim.keymap.set("n", "a", function()
        local default_name = vim.env.HOME

        vim.ui.input({ prompt = "New Name : ", default = default_name }, function(cwd)
            vim.ui.input({ prompt = "New Workspace : " }, function(ws_name)
                wc.add(ws_name, cwd)
            end)
        end
        )
    end, { buffer = buf })

    vim.keymap.set("n", "<CR>", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1] -- [1] ?
        local key = list_view[cursor_row]
        if key and list_view[key] then
            local path = list_view[key]
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end

            if wc.current_workspace and wc.current_workspace ~= "" then
                wc.save_snapshot(wc.current_workspace)
            end

            wc.load_session(cursor_row)
            M.current_workspace = key
        end
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "s", function()
        local default_name = vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
        vim.ui.input({ prompt = "Snapshot Name : ", default = default_name }, function(ws_name)
            if not ws_name or ws_name == "" then return end
            wc.save_current(ws_name)
            M.current_workspace = ws_name
            render()
        end)
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "d", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
        local key = list_view[cursor_row]
        if key then
            wc.delete(cursor_row)
            render()
        end
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "r", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
        local old_name = list_view[cursor_row]
        if old_name then
            vim.ui.input({ prompt = "Rename '" .. old_name .. "' to: ", default = old_name }, function(new_name)
                if not new_name or new_name == "" or new_name == old_name then return end
                wc.rename(old_name, new_name)
                render()
            end)
        end
    end, { buffer = buf, silent = true })
    local function close_win()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    vim.keymap.set("n", "q", close_win, { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, silent = true })
    vim.keymap.set("n", "<leader>ws", function()
        win = vim.api.nvim_open_win(buf, true, get_win_opts())
    end, { desc = "Open Workspace List" })
end

return M
