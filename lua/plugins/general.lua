-- lua/workspace.lua  (Neovim 0.12)
--
-- vim.g.workspace_list = {
--   ["/path/to/tcd"] = { { filename, bufnr }, { filename, bufnr }, ... },
-- }
--
-- bufnr 는 :buffers 에 나오는 실제 번호이고, 진실의 원천(source of truth)은 항상 Neovim 이다.
-- workspace 는 "어떤 bufnr 가 이 tcd 에 속하는가" 만 기억하고,
-- filename 은 표시/복원용 스냅샷이라 읽을 때마다 Neovim 의 실제 이름으로 동기화한다.

local M = {}

local KEY = "workspace_list"
local FILENAME, BUFNR = 1, 2

---------------------------------------------------------------------------
-- storage (vim.g 는 읽을 때 복사본 -> get / 수정 / set)
---------------------------------------------------------------------------

local function load()
    return vim.g[KEY] or {}
end

local function save(ws)
    if next(ws) == nil then
        ws = vim.empty_dict() -- 빈 table 이 list([]) 로 변환되는 것 방지
    end
    vim.g[KEY] = ws
end

local function resolve_tcd(tcd)
    return tcd or vim.fn.getcwd()
end

local function find_index(entries, bufnr)
    for i, e in ipairs(entries) do
        if e[BUFNR] == bufnr then
            return i
        end
    end
end

local function trackable(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr)
        and vim.bo[bufnr].buflisted
        and vim.bo[bufnr].buftype == ""
end

---------------------------------------------------------------------------
-- workspace <-> buffer 등록
---------------------------------------------------------------------------

function M.add(bufnr, tcd)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    tcd = resolve_tcd(tcd)
    if not trackable(bufnr) then
        return
    end

    local ws = load()
    ws[tcd] = ws[tcd] or {} -- 해당 workspace 의 첫 buffer 면 workspace 자동 생성

    local name = vim.api.nvim_buf_get_name(bufnr)
    local idx = find_index(ws[tcd], bufnr)
    if idx then
        ws[tcd][idx][FILENAME] = name
    else
        table.insert(ws[tcd], { name, bufnr })
    end
    save(ws)
end

--- workspace 목록에서만 제외한다 (Neovim buffer 는 건드리지 않음)
function M.remove(bufnr, tcd)
    tcd = resolve_tcd(tcd)
    local ws = load()
    local entries = ws[tcd]
    if not entries then
        return
    end

    local idx = find_index(entries, bufnr)
    if idx then
        table.remove(entries, idx)
    end
    if #entries == 0 then
        ws[tcd] = nil -- 빈 workspace 는 정리
    end
    save(ws)
end

local function remove_from_all(bufnr)
    local ws = load()
    for tcd, entries in pairs(ws) do
        local idx = find_index(entries, bufnr)
        if idx then
            table.remove(entries, idx)
        end
        if #entries == 0 then
            ws[tcd] = nil
        end
    end
    save(ws)
end

--- 이 buffer 를 가진 workspace(tcd) 목록
function M.workspaces_of(bufnr)
    local result = {}
    for tcd, entries in pairs(load()) do
        if find_index(entries, bufnr) then
            table.insert(result, tcd)
        end
    end
    return result
end

---------------------------------------------------------------------------
-- 조회 (stale 정리 + filename 동기화)
---------------------------------------------------------------------------

--- 현재 workspace 의 { {filename, bufnr}, ... } 반환
function M.list(tcd)
    tcd = resolve_tcd(tcd)
    local ws = load()
    local entries = ws[tcd]
    if not entries then
        return {}
    end

    local fresh, changed = {}, false
    for _, e in ipairs(entries) do
        local bufnr = e[BUFNR]
        if trackable(bufnr) then
            local name = vim.api.nvim_buf_get_name(bufnr)
            if name ~= e[FILENAME] then
                changed = true
            end
            table.insert(fresh, { name, bufnr })
        else
            changed = true -- 사라졌거나 unlisted 가 된 buffer
        end
    end

    if changed then
        ws[tcd] = #fresh > 0 and fresh or nil
        save(ws)
    end
    return fresh
end

local function display_name(entry)
    local name = entry[FILENAME]
    name = name ~= "" and vim.fn.fnamemodify(name, ":.") or "[No Name]"
    return string.format("%d  %s", entry[BUFNR], name)
end

---------------------------------------------------------------------------
-- buffer 이동
---------------------------------------------------------------------------

function M.goto_buffer(bufnr)
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_set_current_buf(bufnr)
    end
end

--- 현재 workspace 안에서만 순환 (dir: 1 = next, -1 = prev)
function M.cycle(dir)
    local entries = M.list()
    if #entries == 0 then
        return
    end

    local cur = vim.api.nvim_get_current_buf()
    local idx = find_index(entries, cur) or 0
    local nxt = ((idx - 1 + dir) % #entries) + 1
    M.goto_buffer(entries[nxt][BUFNR])
end

function M.next() M.cycle(1) end

function M.prev() M.cycle(-1) end

--- workspace 의 n 번째 buffer 로 이동 (1-based)
function M.goto_index(n)
    local entry = M.list()[n]
    if entry then
        M.goto_buffer(entry[BUFNR])
    end
end

function M.select()
    local entries = M.list()
    if #entries == 0 then
        vim.notify("workspace 에 buffer 가 없습니다", vim.log.levels.INFO)
        return
    end
    vim.ui.select(entries, {
        prompt = "Workspace buffers",
        format_item = display_name,
    }, function(choice)
        if choice then
            M.goto_buffer(choice[BUFNR])
        end
    end)
end

---------------------------------------------------------------------------
-- buffer 닫기
---------------------------------------------------------------------------

-- 현재 탭에서 bufnr 를 보여주는 window 를 다른 buffer 로 바꿔서 레이아웃이 깨지지 않게 한다.
local function detach_windows(bufnr, alt)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
            if not (alt and vim.api.nvim_buf_is_valid(alt)) then
                alt = vim.api.nvim_create_buf(true, false)
            end
            vim.api.nvim_win_set_buf(win, alt)
        end
    end
end

local function neighbor(entries, bufnr)
    local idx = find_index(entries, bufnr)
    if not idx then
        return nil
    end
    local e = entries[idx + 1] or entries[idx - 1]
    return e and e[BUFNR] or nil
end

--- workspace 에서 buffer 를 닫는다.
--- 다른 workspace 도 이 buffer 를 쓰고 있으면 이 workspace 에서만 빼고 Neovim buffer 는 남긴다.
--- opts.force = true 면 수정된 buffer 도 닫는다.
function M.close(bufnr, tcd, opts)
    opts = opts or {}
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    tcd = resolve_tcd(tcd)

    local entries = M.list(tcd)
    local alt = neighbor(entries, bufnr)
    local used_elsewhere = #M.workspaces_of(bufnr) > 1

    if not used_elsewhere and vim.bo[bufnr].modified and not opts.force then
        vim.notify(
            ("buffer %d 에 저장되지 않은 변경이 있습니다"):format(bufnr),
            vim.log.levels.WARN
        )
        return false
    end

    detach_windows(bufnr, alt)

    if used_elsewhere then
        M.remove(bufnr, tcd)
        return true
    end

    local ok, err = pcall(vim.api.nvim_buf_delete, bufnr, { force = opts.force or false })
    if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
        return false
    end
    return true
end

--- 현재 buffer 만 남기고 workspace 의 나머지를 닫는다
function M.only(tcd, opts)
    tcd = resolve_tcd(tcd)
    local cur = vim.api.nvim_get_current_buf()
    for _, e in ipairs(M.list(tcd)) do
        if e[BUFNR] ~= cur then
            M.close(e[BUFNR], tcd, opts)
        end
    end
end

--- workspace 의 모든 buffer 를 닫는다
function M.close_all(tcd, opts)
    tcd = resolve_tcd(tcd)
    for _, e in ipairs(M.list(tcd)) do
        M.close(e[BUFNR], tcd, opts)
    end
end

---------------------------------------------------------------------------
-- setup
---------------------------------------------------------------------------

function M.setup()
    save({})

    local group = vim.api.nvim_create_augroup("WorkspaceBuffers", { clear = true })

    -- 열리거나 진입한 buffer 를 현재 workspace 에 등록
    vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
        group = group,
        callback = function(args)
            M.add(args.buf)
        end,
    })

    -- :file / :saveas 로 이름이 바뀐 경우 filename 갱신
    vim.api.nvim_create_autocmd("BufFilePost", {
        group = group,
        callback = function(args)
            for _, tcd in ipairs(M.workspaces_of(args.buf)) do
                M.add(args.buf, tcd)
            end
        end,
    })

    -- Neovim 에서 buffer 가 사라지면 (어떤 경로로든) 모든 workspace 에서 제거
    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            remove_from_all(args.buf)
        end,
    })

    -- 이미 열려 있는 buffer 를 현재 workspace 로 초기 등록
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        M.add(b)
    end
end

return M
