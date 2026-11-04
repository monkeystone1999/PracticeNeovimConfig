local M = {}
local workspaces = {}

local width = math.floor(vim.o.columns * 0.5)
local height = math.floor(vim.o.lines * 0.4)
local row = math.floor((vim.o.lines - height) / 2)
local col = math.floor((vim.o.columns - width) / 2)


local function get_path()
    return vim.fn.stdpath("data") .. "/Workspace"
end

local dir_path = vim.fn.stdpath("data") .. "/WorkspaceList"
local file_path = dir_path .. "WorkspaceList.json"
local sessions_dir = dir_path .. "/sessions"

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

local function save_snapshot(ws_name)
    if not ws_name or ws_name == "" then return end
    ensure_dir()

    local current_cwd = vim.fn.getcwd(0)
    workspaces[ws_name] = current_cwd
    save_workspace_list()

    local session_file = sessions_dir .. "/" .. ws_name .. ".vim"
    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file))
end

local function load_workspace_session(ws_name, target_path)
    ensure_dir()
    local session_file = sessions_dir .. "/" .. ws_name .. ".vim"

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
        title = " 📁 Workspace List (s:Save Current, a:Add, d:Delete, r:Rename, Enter:Select) ",
        title_pos = "center",
    })
end

--[[
if vim.fn.isdirectory(get_path()) == 0 then
    vim.fn.mkdir(get_path(), "p")
end

local function truncate_list()
    local file = io.open(file_path, "w")
    if not file then return false end

    local encoded = vim.json.encode(workspaces)
    file:write(encoded)
    file:close()
    return true;
end

local function load_workspace()
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

local function ensure_dir()
    if vim.fn.isdirectory(get_path()) == 0 then
        vim.fn.mkdir(get_path(), "p")
    end
end


local M = {}

function M.setup()
    ensure_dir()
    vim.api.nvim_create_autocmd("VimEnter", {
        pattern = '*',
        callback = function(args)
            local arg = vim.vim.fn.argv(0)
            if #arg == 0 then
                workspaces = load_workspace()
                local buf = vim.api.nvim_create_buf(false, false)
                -- Open and Clickable? Button like
            end
        end
    })
    vim.api.nvim_create_autocmd("VimLeave", {
        pattern = '*',
        callback = function(args)
            truncate_list()
        end
    })
end

function M.workspace_list_get()
    return workspaces
end

function M.workspace_list_add(key, value)
    workspaces[key] = value
end

function M.workspace_list_change_key(before, after)
    local v = workspaces[before]
    workspaces[before] = nil
    workspaces[after] = v
end

function M.workspace_list_delete(key)
    if workspaces[key] ~= nil then
        workspaces[key] = nil
        return true
    end
    return false
end

function M.open_workspace_list_ui()
    workspaces = load_workspace()

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = "workspace_list"

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.max(width, 40),
        height = math.max(height, 8),
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "📁 Workspace List (a:Add, d:Delete, r:Rename, Enter:Select)",
        title_pos = "center",
    })

    local workspace_viewer = {}
    local function render()
        workspace_viewer = {}
        local lines = {}
        for name, path in pairs(workspaces) do
            table.insert(workspace_viewer, name)
            table.insert(lines, string.format("  • %-15s : %s", name, path))
        end
    end
    vim.keymap.set("n", "<CR>", function()
        local cursor_row = vim.api.nvim_win_get_cursor(win)
        local key = keys_list[cursor_row]
    end, { buf = buf, silent = true })
end

return M

-- {
-- "name" : "locate",
-- "name" : "locate"
-- }
 ]]
