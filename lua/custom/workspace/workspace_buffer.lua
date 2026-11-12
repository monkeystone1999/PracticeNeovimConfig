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
        footer_pos = "center",
    }
end

local buf = nil
local win = nil

function M.setup()
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].filetype = "workspace_list"

    local list_view = {}
    local function render()
        list_view = {}
        local lines = {}
        local current_cwd = vim.fn.getcwd(0)

        for _, item in ipairs(wc.get_list()) do
            table.insert(list_view, item.name)
            local is_active = (item.path == current_cwd) and " *(active)*" or ""
            table.insert(lines, string.format(" • %-15s : %s%s", item.name, item.path, is_active))
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
        local default_path = vim.fn.getcwd(0)
        vim.ui.input({ prompt = "Workspace Path : ", default = default_path }, function(cwd)
            if not cwd or cwd == "" then return end
            vim.ui.input({ prompt = "Workspace Name : " }, function(ws_name)
                if not ws_name or ws_name == "" then return end
                wc.add(ws_name, cwd)
                render()
            end)
        end)
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "<CR>", function()
        if not win or not vim.api.nvim_win_is_valid(win) then return end
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
        local key = list_view[cursor_row]
        if key then
            vim.api.nvim_win_close(win, true)
            wc.save_load(key)
        end
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "s", function()
        local default_name = vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
        vim.ui.input({ prompt = "Snapshot Name : ", default = default_name }, function(ws_name)
            if not ws_name or ws_name == "" then return end
            wc.save_current(ws_name)
            render()
        end)
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "d", function()
        if not win or not vim.api.nvim_win_is_valid(win) then return end
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
        local key = list_view[cursor_row]
        if key then
            wc.delete(key)
            render()
        end
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "r", function()
        if not win or not vim.api.nvim_win_is_valid(win) then return end
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
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    vim.keymap.set("n", "q", close_win, { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, silent = true })
    vim.keymap.set("n", "<leader>ws", function()
        render()
        win = vim.api.nvim_open_win(buf, true, get_win_opts())
    end, { desc = "Open Workspace List" })
end

return M
