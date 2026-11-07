local M = {}
local Entry = require("custom.bases.entry")

local workspaces = {}
local dir_path = vim.fn.stdpath("data") .. "/WorkspaceList"
local file_path = dir_path .. "/WorkspaceList.json"
local sessions_dir = dir_path .. "/sessions"

local function get_session(session_name)
    return sessions_dir .. "/" .. session_name .. ".vim"
end

local function ensure_dir()
    if vim.fn.isdirectory(dir_path) == 0 then
        vim.fn.mkdir(dir_path, "p")
    end
    if vim.fn.isdirectory(sessions_dir) == 0 then
        vim.fn.mkdir(sessions_dir, "p")
    end
end

local function save_workspace_list()
    local file = io.open(file_path, "w")
    if not file then
        return false
    end
    file:write(vim.json.encode(workspaces))
    file:close()
    return true
end

local function load_workspace_list()
    local file = io.open(file_path, "r")
    if not file then
        return {}
    end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then
        return {}
    end
    local ok, decoded = pcall(vim.json.decode, content)
    return ok and decoded or {}
end

local function find_workspace_by_path(target_path)
    local normalized_target = vim.fn.fnamemodify(target_path, ":p"):gsub("/$", "")
    for name, path in pairs(workspaces) do
        local normalized_path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
        if normalized_path == normalized_target then
            return name
        end
    end
    return nil
end

local function save_snapshot(ws_name)
    if not ws_name or ws_name == "" then return end
    ensure_dir()

    local current_cwd = vim.fn.getcwd(0)
    workspaces[ws_name] = current_cwd
    save_workspace_list()

    local session_file = get_session(ws_name)
    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file))
end

local function load_workspace_session(ws_name, target_path)
    ensure_dir()
    local session_file = get_session(ws_name)

    pcall(vim.cmd.tcd, target_path)
    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! %db!")
        vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
    else
        print(" Switched to directory: " .. target_path)
    end
end


function M.open_workspace_list_ui()
    workspaces = load_workspace_list()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = "workspace_list"

    local width = math.floor(vim.o.columns * 0.5)
    local height = math.floor(vim.o.lines * 0.4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.max(width, 40),
        height = math.max(height, 8),
        row = row,
        col = col,
        style = "minimal",
        border = "rounded", -- 둥근 테두리 적용
        title = "Workspace List",
        title_pos = "center",
        footer = "s:Save Current, a:Add, d:Delete, r:Rename, Enter:Select",
        footer_pos = "center"
    })
    local list_view = {}
    local function render()
        list_view = {}
        local lines = {}
        local current_cwd = vim.fn.getcwd(0)

        for name, path in pairs(workspaces) do
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

    vim.keymap.set("n", "<CR>", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1] -- [1] ?
        local key = list_view[cursor_row]
        if key and workspaces[key] then
            local path = workspaces[key]
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end

            if M.current_workspace and M.current_workspace ~= "" then
                save_snapshot(M.current_workspace)
            end

            load_workspace_session(key, path)
            M.current_workspace = key
        end
    end, { buffer = buf, silent = true })

    vim.keymap.set("n", "s", function()
        local default_name = vim.fn.fnamemodify(vim.fn.getcwd(0), ":t")
        vim.ui.input({ prompt = "Snapshot Name : ", default = default_name }, function(name)
            if not name or name == "" then return end
            save_snapshot(name)
            M.current_workspace = name
            render()
        end)
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "d", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
        local key = list_view[cursor_row]
        if key then
            workspaces[key] = nil
            save_workspace_list()
            local session_file = get_session(key)
            if vim.fn.filereadable(session_file) == 1 then
                vim.fn.delete(session_file)
            end
            render()
        end
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "r", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
        local old_name = list_view[cursor_row]
        if old_name then
            vim.ui.input({ prompt = "Rename '" .. old_name .. "' to: ", default = old_name }, function(new_name)
                if not new_name or new_name == "" or new_name == old_name then return end
                local path = workspaces[old_name]
                workspaces[old_name] = nil
                workspaces[new_name] = path
                save_workspace_list()
                local old_session = get_session(old_name)
                local new_session = get_session(new_name)
                if vim.fn.filereadable(old_session) == 1 then
                    vim.fn.rename(old_session, new_session)
                end
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
end

function M.setup()
    ensure_dir()
    vim.opt.sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos"
    vim.api.nvim_create_autocmd("VimEnter", {
        pattern = "*",
        callback = function()
            local entry_typ, path = Entry.detect_entry_type()
            if entry_typ == "empty" then
                M.open_workspace_list_ui()
            elseif entry_typ == "dir" and path then
                pcall(vim.cmd.tcd, path)
                local matched_name = find_workspace_by_path(path)
                if matched_name then
                    load_workspace_session(matched_name, path)
                    M.current_workspace = matched_name
                end
            elseif entry_typ == "file" then

            end
        end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if M.current_workspace then
                save_snapshot(M.current_workspace)
            end
        end
    })
    vim.keymap.set("n", "<leader>ws", M.open_workspace_list_ui, { desc = "Open Workspace List" })
end

return M
