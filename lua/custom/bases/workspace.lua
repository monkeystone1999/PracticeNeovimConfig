local M = {}

local etr = require("custom.bases.entry")

local workspaces = {}
local dir_path = vim.fn.stdpath("data") .. "/WorkspaceList"
local file_path = dir_path .. "/WorkspaceList.json"
local sessions_dir = dir_path .. "/sessions"

-- ws_name = session_name
-- ws_name 으로써 string 이다
M.current_workspace = nil

-- obsidian.nvim 실시간 재동기화 콜백
local on_obsidian_sync = nil

function M.set_obsidian_sync_callback(cb)
    on_obsidian_sync = cb
end

function M.sync_obsidian()
    if type(on_obsidian_sync) == "function" then
        pcall(on_obsidian_sync)
    end
end

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
    local ok, parsed = pcall(vim.json.decode, content)

    if ok then
        workspaces = parsed or {}
    else
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

-- 워크스페이스 루트(tcd)에 README.md 템플릿과 docs/ 폴더를 생성하는 함수
function M.init_docs_template(ws_name, root_path)
    root_path = etr.normalize(root_path or vim.fn.getcwd(0))
    ws_name = ws_name or M.find_by_path(root_path) or vim.fn.fnamemodify(root_path, ":t")

    if vim.fn.isdirectory(root_path) == 0 then
        vim.fn.mkdir(root_path, "p")
    end

    -- 1) <root>/docs 폴더 생성
    local docs_dir = vim.fs.joinpath(root_path, "docs")
    if vim.fn.isdirectory(docs_dir) == 0 then
        vim.fn.mkdir(docs_dir, "p")
    end

    -- 2) <root>/README.md 템플릿 파일 생성 (이미 존재하면 덮어쓰지 않고 보존)
    local readme_path = vim.fs.joinpath(root_path, "README.md")
    if vim.fn.filereadable(readme_path) == 0 then
        local f = io.open(readme_path, "w")
        if f then
            f:write(string.format(
                "# %s\n\n## Overview\n\n- **Workspace**: `%s`\n- **Root Path**: `%s`\n- **Docs Directory**: [`docs/`](./docs)\n\n## Documentation\n\n",
                ws_name,
                ws_name,
                root_path
            ))
            f:close()
        end
    end

    return ws_name, root_path
end

-- obsidian.nvim 의 opts.workspaces 에 주입할 워크스페이스 목록 반환
-- (루트의 README.md 까지 함께 편집할 수 있도록 path 는 root_path 로 잡고, 새 노트는 docs/ 하위에 생성)
function M.get_obsidian_workspaces()
    local nvim_config_root = etr.normalize(vim.fn.stdpath("config"))
    M.init_docs_template("neovim", nvim_config_root)

    local obs_workspaces = {
        {
            name = "neovim",
            path = nvim_config_root,
            overrides = {
                notes_subdir = "docs",
            },
        },
    }

    local seen_names = { neovim = true }
    local seen_paths = { [nvim_config_root] = true }

    for _, item in ipairs(M.get_list()) do
        local norm_path = etr.normalize(item.path)
        if vim.fn.isdirectory(norm_path) == 1 and not seen_names[item.name] and not seen_paths[norm_path] then
            -- docs 폴더가 없으면 생성해 두어 obsidian.nvim 연동 보장
            local docs_dir = vim.fs.joinpath(norm_path, "docs")
            if vim.fn.isdirectory(docs_dir) == 0 then
                pcall(vim.fn.mkdir, docs_dir, "p")
            end

            table.insert(obs_workspaces, {
                name = item.name,
                path = norm_path,
                overrides = {
                    notes_subdir = "docs",
                },
            })
            seen_names[item.name] = true
            seen_paths[norm_path] = true
        end
    end

    return obs_workspaces
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
    local current_cwd = etr.normalize(vim.fn.getcwd(0))
    workspaces[ws_name] = current_cwd
    save_workspace_list()
    M.init_docs_template(ws_name, current_cwd)
    M.sync_obsidian()

    local session_file = get_session(ws_name)
    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file))
end

function M.setup()
    ensure_dir()
    load_workspaces()

    -- 수동으로도 현재 tcd 루트에 README.md + docs/ 생성 및 워크스페이스/Obsidian 등록 가능한 명령어
    vim.api.nvim_create_user_command("WorkspaceInitDocs", function(cmd_opts)
        local cwd = etr.normalize(vim.fn.getcwd(0))
        local ws_name = (cmd_opts.args ~= "" and cmd_opts.args)
            or M.find_by_path(cwd)
            or vim.fn.fnamemodify(cwd, ":t")

        M.init_docs_template(ws_name, cwd)
        if not workspaces[ws_name] then
            workspaces[ws_name] = cwd
            save_workspace_list()
        end
        M.sync_obsidian()
        vim.notify(
            string.format("Workspace '%s' (%s) 에 README.md 및 docs/ 템플릿이 준비되고 Obsidian에 등록되었습니다.", ws_name, cwd),
            vim.log.levels.INFO,
            { title = "Workspace & Obsidian" }
        )
    end, {
        nargs = "?",
        desc = "현재 작업 경로(tcd)에 README.md와 docs/ 폴더를 생성하고 Obsidian 워크스페이스에 추가",
    })

    vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
            local cwd = etr.normalize(vim.fn.getcwd(0))
            M.current_workspace = M.find_by_path(cwd)
        end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if M.current_workspace then
                M.save_snapshot(M.current_workspace)
            end
        end
    })
end

-- 현재 탭의 작업 디렉터리(tcd)만 변경 (열려 있는 버퍼/세션 유지)
function M.set_tcd(target_path)
    if not target_path or target_path == "" then
        return false, "empty path"
    end
    local norm_path = etr.normalize(vim.fn.expand(target_path))
    if vim.fn.isdirectory(norm_path) == 0 then
        vim.notify("존재하지 않는 디렉터리입니다: " .. norm_path, vim.log.levels.WARN, { title = "Workspace" })
        return false, "not a directory"
    end
    pcall(vim.cmd.tcd, norm_path)
    M.current_workspace = M.find_by_path(norm_path)
    vim.notify("tcd 변경됨: " .. norm_path, vim.log.levels.INFO, { title = "Workspace" })
    return true, norm_path
end

-- 등록된 워크스페이스의 저장 경로(location) 변경 및 tcd 이동
function M.relocate(ws_name, new_cwd)
    if not ws_name or ws_name == "" or not workspaces[ws_name] then
        return false, "not found"
    end
    if not new_cwd or new_cwd == "" then
        return false, "empty path"
    end
    local norm_path = etr.normalize(vim.fn.expand(new_cwd))
    if vim.fn.isdirectory(norm_path) == 0 then
        vim.notify("존재하지 않는 디렉터리입니다: " .. norm_path, vim.log.levels.WARN, { title = "Workspace" })
        return false, "not a directory"
    end

    workspaces[ws_name] = norm_path
    save_workspace_list()
    M.init_docs_template(ws_name, norm_path)
    M.sync_obsidian()

    pcall(vim.cmd.tcd, norm_path)
    M.current_workspace = ws_name
    vim.notify(string.format("Workspace '%s' 경로 변경 및 tcd 적용: %s", ws_name, norm_path), vim.log.levels.INFO,
        { title = "Workspace" })
    return true, norm_path
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
            M.init_docs_template(ws_name, ws_cwd)
            M.sync_obsidian()
            return true
        end
    end
    workspaces[ws_name] = ws_cwd
    save_workspace_list()
    M.init_docs_template(ws_name, ws_cwd)
    M.sync_obsidian()
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
    M.init_docs_template(ws_name, cwd)
    M.sync_obsidian()
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
    M.sync_obsidian()
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
    M.sync_obsidian()
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
