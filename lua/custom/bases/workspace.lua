local M = {}

local etr = require("custom.bases.entry")

local workspaces = {}
local dir_path = vim.fn.stdpath("data") .. "/WorkspaceList"
local file_path = dir_path .. "/WorkspaceList.json"
local sessions_dir = dir_path .. "/sessions"

-- ws_name = session_name
-- M.current_workspace 는 "현재 세션이 로드된(=종료/전환 시 저장될) 워크스페이스 이름" 이다.
-- cwd 가 등록 경로와 일치한다는 이유만으로 설정하지 않는다. (다른 버퍼 상태가 세션을 덮어쓰는 것 방지)
-- 설정되는 곳: M.load(), M.save_current() 뿐
M.current_workspace = nil

-- obsidian.nvim 실시간 재동기화 콜백
local on_obsidian_sync = nil

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "Workspace" })
end

local function fail(msg)
    notify(msg, vim.log.levels.WARN)
    return false, msg
end

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
        workspaces = {}
        return
    end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then
        workspaces = {}
        return
    end
    local ok, parsed = pcall(vim.json.decode, content)
    workspaces = (ok and type(parsed) == "table") and parsed or {}
end

local function get_session(session_name)
    return sessions_dir .. "/" .. session_name .. ".vim"
end

-- 세션 파일명으로 안전한 이름인지 검사 (경로 구분자/Windows 금지 문자/. .. 차단)
local function validate_name(name)
    if type(name) ~= "string" then return false, "이름이 비어 있습니다" end
    name = vim.trim(name)
    if name == "" then return false, "이름이 비어 있습니다" end
    if name == "." or name == ".." or name:find('[/\\:%*%?"<>|]') then
        return false, "이름에 사용할 수 없는 문자가 있습니다: " .. name
    end
    return true, name
end

-- 저장되지 않은(modified) 일반 파일/acwrite(oil 등) 버퍼 목록
function M.unsaved_buffers()
    local list = {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local bt = vim.bo[b].buftype
        if vim.bo[b].buflisted and vim.bo[b].modified and (bt == "" or bt == "acwrite") then
            local name = vim.api.nvim_buf_get_name(b)
            table.insert(list, name ~= "" and vim.fn.fnamemodify(name, ":~:.") or ("[No Name] #" .. b))
        end
    end
    return list
end

-- 목록(listed) 버퍼만 삭제한다.
-- `%bdelete!` 는 unlisted 지만 로드된 스크래치 버퍼(워크스페이스 목록/대시보드 패널)까지 지워
-- buffer-local keymap 이 사라지고, 수정된 버퍼를 강제로 버리므로 사용하지 않는다.
-- 저장 안 된 버퍼가 있으면 아무것도 지우지 않고 false 반환.
function M.clear_buffers()
    local unsaved = M.unsaved_buffers()
    if #unsaved > 0 then
        return fail("저장되지 않은 버퍼가 있어 전환을 취소했습니다:\n  " .. table.concat(unsaved, "\n  "))
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted then
            -- 실행 중인 터미널 등 삭제 불가 버퍼는 그대로 둔다
            pcall(vim.cmd, "silent bdelete " .. b)
        end
    end
    return true
end

local function load_workspace_session(ws_name, target_path)
    if not M.clear_buffers() then
        return false
    end

    local session_file = get_session(ws_name)
    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
    end
    -- 세션 파일 안의 cd/tcd(예: Relocate 이전의 옛 경로)가 덮어쓰지 않도록 source 이후에 적용
    local ok = pcall(vim.cmd.tcd, target_path)
    if not ok then
        notify("디렉터리로 이동할 수 없습니다: " .. target_path, vim.log.levels.WARN)
    end
    return true
end

local function save_workspace_list()
    local file = io.open(file_path, "w")
    if not file then
        notify("워크스페이스 목록을 저장할 수 없습니다: " .. file_path, vim.log.levels.ERROR)
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
        if etr.normalize(path) == normalized_target then
            return name
        end
    end
    return nil
end

-- 현재 에디터 상태를 ws_name 의 세션 파일로 저장 (등록 경로는 변경하지 않음)
function M.save_snapshot(ws_name)
    if not ws_name or ws_name == "" or not workspaces[ws_name] then return false end
    ensure_dir()
    local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(get_session(ws_name)))
    if not ok then
        return fail(string.format("'%s' 세션 저장 실패: %s", ws_name, tostring(err)))
    end
    return true
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

        local valid, res = validate_name(ws_name)
        if not valid then
            fail(res)
            return
        end
        ws_name = res

        if workspaces[ws_name] and etr.normalize(workspaces[ws_name]) ~= cwd then
            fail(string.format("'%s' 는 이미 다른 경로(%s)에 등록되어 있습니다.", ws_name, workspaces[ws_name]))
            return
        end
        local existing = M.find_by_path(cwd)
        if existing and existing ~= ws_name then
            fail(string.format("현재 경로는 이미 '%s' 로 등록되어 있습니다.", existing))
            return
        end

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

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if M.current_workspace then
                M.save_snapshot(M.current_workspace)
            end
        end
    })
end

-- 현재 탭의 작업 디렉터리(tcd)만 변경 (열려 있는 버퍼/세션 및 current_workspace 유지)
function M.set_tcd(target_path)
    if not target_path or target_path == "" then
        return false, "empty path"
    end
    local norm_path = etr.normalize(vim.fn.expand(target_path))
    if vim.fn.isdirectory(norm_path) == 0 then
        return fail("존재하지 않는 디렉터리입니다: " .. norm_path)
    end
    pcall(vim.cmd.tcd, norm_path)
    notify("tcd 변경됨: " .. norm_path)
    return true, norm_path
end

-- 등록된 워크스페이스의 저장 경로(location) 변경
-- 현재 로드된 워크스페이스라면 tcd 도 이동하고 세션을 새 경로 기준으로 다시 저장한다.
function M.relocate(ws_name, new_cwd)
    if not ws_name or ws_name == "" or not workspaces[ws_name] then
        return fail("워크스페이스를 찾을 수 없습니다: " .. tostring(ws_name))
    end
    if not new_cwd or new_cwd == "" then
        return false, "empty path"
    end
    local norm_path = etr.normalize(vim.fn.expand(new_cwd))
    if vim.fn.isdirectory(norm_path) == 0 then
        return fail("존재하지 않는 디렉터리입니다: " .. norm_path)
    end
    local owner = M.find_by_path(norm_path)
    if owner and owner ~= ws_name then
        return fail(string.format("해당 경로는 이미 '%s' 로 등록되어 있습니다.", owner))
    end

    workspaces[ws_name] = norm_path
    save_workspace_list()
    M.init_docs_template(ws_name, norm_path)
    M.sync_obsidian()

    if M.current_workspace == ws_name then
        pcall(vim.cmd.tcd, norm_path)
        M.save_snapshot(ws_name)
    end
    notify(string.format("Workspace '%s' 경로 변경: %s", ws_name, norm_path))
    return true, norm_path
end

-- ws_cwd 는 절대경로여야함
function M.add(ws_name, ws_cwd)
    local valid, res = validate_name(ws_name)
    if not valid then return fail(res) end
    ws_name = res
    if not ws_cwd or ws_cwd == "" then return false, "empty path" end
    ws_cwd = etr.normalize(vim.fn.expand(ws_cwd))
    if vim.fn.isdirectory(ws_cwd) == 0 then
        return fail("존재하지 않는 디렉터리입니다: " .. ws_cwd)
    end

    -- 중복 방지 (이름/경로 모두 1:1)
    if workspaces[ws_name] then
        return fail(string.format("'%s' 이름이 이미 존재합니다.", ws_name))
    end
    local owner = M.find_by_path(ws_cwd)
    if owner then
        return fail(string.format("해당 경로는 이미 '%s' 로 등록되어 있습니다. (이름 변경은 r)", owner))
    end

    workspaces[ws_name] = ws_cwd
    save_workspace_list()
    M.init_docs_template(ws_name, ws_cwd)
    M.sync_obsidian()
    return true
end

-- 현재 cwd 와 에디터 상태를 ws_name 으로 저장하고, 이후 이 워크스페이스를 현재 워크스페이스로 추적
function M.save_current(ws_name)
    local cwd = etr.normalize(vim.fn.getcwd(0))
    local existing = M.find_by_path(cwd)
    ws_name = ws_name or existing
    local valid, res = validate_name(ws_name)
    if not valid then return fail(res) end
    ws_name = res

    if existing and existing ~= ws_name then
        return fail(string.format("현재 경로는 이미 '%s' 로 등록되어 있습니다. (이름 변경은 r)", existing))
    end
    if workspaces[ws_name] and etr.normalize(workspaces[ws_name]) ~= cwd then
        return fail(string.format("'%s' 는 다른 경로(%s)에 등록되어 있습니다. (경로 변경은 C)", ws_name, workspaces[ws_name]))
    end

    workspaces[ws_name] = cwd
    save_workspace_list()
    M.init_docs_template(ws_name, cwd)
    M.sync_obsidian()
    if not M.save_snapshot(ws_name) then
        return false, "session save failed"
    end
    M.current_workspace = ws_name
    notify(string.format("Workspace '%s' 저장됨: %s", ws_name, cwd))
    return true
end

function M.rename(old_name, new_name)
    if not old_name or old_name == "" then return false, "empty name" end
    local valid, res = validate_name(new_name)
    if not valid then return fail(res) end
    new_name = res
    if old_name == new_name then
        return true
    end
    if not workspaces[old_name] then return fail("워크스페이스를 찾을 수 없습니다: " .. old_name) end
    if workspaces[new_name] then
        return fail(string.format("'%s' 이름이 이미 존재합니다.", new_name))
    end

    local old_s, new_s = get_session(old_name), get_session(new_name)
    if vim.fn.filereadable(old_s) == 1 and vim.fn.rename(old_s, new_s) ~= 0 then
        return fail("세션 파일 이름을 변경할 수 없습니다: " .. old_s)
    end
    workspaces[new_name] = workspaces[old_name]
    workspaces[old_name] = nil
    save_workspace_list()
    if M.current_workspace == old_name then
        M.current_workspace = new_name
    end
    M.sync_obsidian()
    return true
end

function M.delete(ws_name)
    if not ws_name or ws_name == "" then return false, "empty name" end
    if not workspaces[ws_name] then return fail("워크스페이스를 찾을 수 없습니다: " .. ws_name) end
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

-- 워크스페이스 세션을 로드한다. 저장되지 않은 버퍼가 있으면 아무것도 바꾸지 않고 false.
function M.load(ws_name)
    if not ws_name or ws_name == "" then return false end
    local cwd = workspaces[ws_name]
    if not cwd then return fail("워크스페이스를 찾을 수 없습니다: " .. ws_name) end
    if not load_workspace_session(ws_name, cwd) then
        return false
    end
    M.current_workspace = ws_name
    return true
end

function M.save_load(target_name)
    -- 전환 불가 상태(저장 안 된 버퍼)면 현재 세션도 건드리지 않음
    if #M.unsaved_buffers() > 0 then
        return M.clear_buffers()
    end
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

-- 목록 UI 의 *(active)* 표시용 (Windows 경로 구분자 차이 흡수)
function M.is_cwd(path)
    return etr.normalize(path) == etr.normalize(vim.fn.getcwd(0))
end

return M
