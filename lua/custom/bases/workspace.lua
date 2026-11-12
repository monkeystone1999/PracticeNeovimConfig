local M = {}

local etr = require("custom.bases.entry")

local workspaces = {}
local dir_path = vim.fn.stdpath("data") .. "/WorkspaceList"
local file_path = dir_path .. "/WorkspaceList.json"
local sessions_dir = dir_path .. "/sessions"

-- ws_name = session_name
-- ws_name 으로써 string 이다
M.current_workspace = nil

local function load_workspaces()
    local file = io.open(file_path, "r")
    if not file then
        return {}
    end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then
        return {}
    end
    -- 수정된 부분: pcall의 반환값을 분리해서 처리합니다.
    local ok, parsed = pcall(vim.json.decode, content)

    if ok then
        workspaces = parsed or {}
    else
        -- JSON 파싱에 실패했을 때 빈 테이블을 할당하거나 에러 메시지를 띄울 수 있습니다.
        workspaces = {}
    end
end

local function get_session(session_name)
    return sessions_dir .. "/" .. session_name .. ".vim"
end

local function load_workspace_session(ws_name, target_path)
    local session_file = get_session(ws_name)

    pcall(vim.cmd.tcd, target_path)
    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! %bdelete!")
        vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
    else
        print(" Switched to directory: " .. target_path)
    end
end

local function load_session(session_name)
    local session_file = get_session(session_name)

    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! %bdelete!")
        vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
    else
        print(" Switched to directory: " .. session_name)
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

local function ensure_dir()
    if vim.fn.isdirectory(dir_path) == 0 then
        vim.fn.mkdir(dir_path, "p")
    end
    if vim.fn.isdirectory(sessions_dir) == 0 then
        vim.fn.mkdir(sessions_dir, "p")
    end
end

function M.find_by_path(target_path)
    local normalized_target = etr.normalize(target_path)
    for name, path in pairs(workspaces) do
        local normalized_path = etr.normalize(path)
        if normalized_path == normalized_target then
            return name
        end
    end
    return nil
end

function M.save_snapshot(ws_name)
    if not ws_name or ws_name == "" then return end
    local current_cwd = vim.fn.getcwd(0)
    workspaces[ws_name] = current_cwd
    save_workspace_list()

    local session_file = get_session(ws_name)
    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file))
end

function M.setup()
    ensure_dir()
    load_workspaces()
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if M.current_workspace then
                M.save_snapshot(M.current_workspace)
            end
        end
    })
end

-- ws_cwd 는 절대경로여야함
function M.add(ws_name, ws_cwd)
    if not ws_name or ws_name == "" then return end
    if not ws_cwd or ws_cwd == "" then return end
    ws_cwd = etr.normalize(ws_cwd)
    -- 중복 제거
    if workspaces[ws_name] then return false, "name exists" end

    for ws, cwd in pairs(workspaces) do
        if cwd == ws_cwd then
            workspaces[ws] = nil
            workspaces[ws_name] = ws_cwd
            save_workspace_list()
            return true
        end
    end
    workspaces[ws_name] = ws_cwd
    save_workspace_list()
    return true
end

function M.save_current(ws_name)
    local cwd = etr.normalize(vim.fn.getcwd(0))
    local existing = M.find_by_path(cwd)
    ws_name = ws_name or existing
    if not ws_name then return false, "name required" end

    if existing and existing ~= ws_name then return false, "path exists", existing end
    workspaces[ws_name] = cwd
    save_workspace_list()
    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(get_session(ws_name)))
    M.current_workspace = ws_name
    return true
end

function M.rename(old_name, new_name)
    if not old_name or old_name == "" then return end
    if not new_name or new_name == "" then return end
    if old_name == new_name then
        return
    end
    if not workspaces[old_name] then return false, "not found" end
    workspaces[new_name] = workspaces[old_name]
    workspaces[old_name] = nil
    save_workspace_list()
    local old_s, new_s = get_session(old_name), get_session(new_name)
    if vim.fn.filereadable(old_s) == 1 then
        vim.fn.rename(old_s, new_s)
    end
    if M.current_workspace == old_name then
        M.current_workspace = new_name
    end
    return true
end

function M.delete(ws_name)
    if not ws_name or ws_name == "" then return end
    if not workspaces[ws_name] then return false, "not found" end
    workspaces[ws_name] = nil
    save_workspace_list()
    local session_file = get_session(ws_name)
    if vim.fn.filereadable(session_file) == 1 then
        vim.fn.delete(session_file)
    end
    if M.current_workspace == ws_name then
        M.current_workspace = nil
    end
    return true
end

function M.load(ws_name)
    if not ws_name or ws_name == "" then return end
    local cwd = workspaces[ws_name]
    if not cwd then return false end
    load_workspace_session(ws_name, cwd)
    M.current_workspace = ws_name
    return true
end

function M.save_load(target_name)
    if M.current_workspace and M.current_workspace ~= "" then
        M.save_snapshot(M.current_workspace)
    end
    return M.load(target_name)
end

function M.get_list()
    local items = {}
    for name, path in pairs(workspaces) do
        items[#items + 1] = { name = name, path = path }
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    return items
end

return M
