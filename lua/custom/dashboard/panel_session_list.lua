local M = {}

local workspace = require("custom.bases.workspace")
local buffer = nil
local list_view = {}

local callbacks = {
    close = function() end,
}

local panel = {
    title = "Workspaces",
    content = {},
}

function M.set_callbacks(cbs)
    callbacks = vim.tbl_extend("force", callbacks, cbs or {})
end

function M.get_content()
    list_view = {}
    local ws_list = workspace.get_list()
    local current_cwd = vim.fn.getcwd(0)

    if #ws_list == 0 then
        panel.content = { " (등록된 Workspace가 없습니다. 's' 저장 / 'a' 추가)" }
    else
        local lines = {}
        for _, item in ipairs(ws_list) do
            table.insert(list_view, item.name)
            local is_active = (item.path == current_cwd) and " *(active)*" or ""
            table.insert(lines, string.format(" • %-15s : %s%s", item.name, item.path, is_active))
        end
        panel.content = lines
    end
    return panel.content
end

function M.refresh()
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return
    end
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, M.get_content())
    vim.bo[buffer].modifiable = false
end

local function bind_keymaps()
    local opts = { buffer = buffer, silent = true, nowait = true }

    -- Enter(<CR>): 커서가 위치한 워크스페이스 선택 및 로드
    vim.keymap.set("n", "<CR>", function()
        local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
        local key = list_view[cursor_row]
        if key then
            callbacks.close()
            workspace.save_load(key)
        end
    end, opts)

    -- a: 새 워크스페이스 경로 및 이름 등록
    vim.keymap.set("n", "a", function()
        local default_path = vim.fn.getcwd(0)
        vim.ui.input({ prompt = "Workspace Path : ", default = default_path }, function(cwd)
            if not cwd or cwd == "" then return end
            vim.ui.input({ prompt = "Workspace Name : " }, function(ws_name)
                if not ws_name or ws_name == "" then return end
                workspace.add(ws_name, cwd)
                M.refresh()
            end)
        end)
    end, opts)

    -- s: 현재 작업 디렉터리 상태를 스냅샷으로 저장
    vim.keymap.set("n", "s", function()
        local default_name = vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
        vim.ui.input({ prompt = "Snapshot Name : ", default = default_name }, function(ws_name)
            if not ws_name or ws_name == "" then return end
            workspace.save_current(ws_name)
            M.refresh()
        end)
    end, opts)

    -- d: 커서가 위치한 워크스페이스 삭제
    vim.keymap.set("n", "d", function()
        local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
        local key = list_view[cursor_row]
        if key then
            workspace.delete(key)
            M.refresh()
        end
    end, opts)

    -- r: 커서가 위치한 워크스페이스 이름 변경
    vim.keymap.set("n", "r", function()
        local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
        local old_name = list_view[cursor_row]
        if old_name then
            vim.ui.input({ prompt = "Rename '" .. old_name .. "' to: ", default = old_name }, function(new_name)
                if not new_name or new_name == "" or new_name == old_name then return end
                workspace.rename(old_name, new_name)
                M.refresh()
            end)
        end
    end, opts)
end

function M.setup()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].buftype = "nofile"
    bind_keymaps()
end

function M.get_panel(row, col, width, height)
    M.refresh()
    local win_config = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = panel.title,
        title_pos = "center",
        footer = " s:Save, a:Add, d:Delete, r:Rename, Enter:Select ",
        footer_pos = "center",
    }
    return { win_config, buffer }
end

return M
