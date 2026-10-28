local M = {}

local tabpages = {}

local function resolve(tab)
    return (tab == nil or tab == 0) and vim.api.nvim_get_current_tabpage() or tab
end

local function abs(path)
    -- fname: string, mods: string
    return vim.fs.normalize(vim.fn.fnamemodify(vim.fs.normalize(path), ":p"))
end

local function tcd(path)
    vim.cmd("tcd " .. vim.fn.fnameescape(path))
end

function M.get(tab)
    tab = resolve(tab)
    tabpages[tab] = tabpages[tab] or { bufs = {} }
    return tabpages[tab]
end

function M.root(tab)
    -- winnr?: integer, tabnr?: integer
    return vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(resolve(tab)))
end

function M.name(tab)
    local root = M.root(tab)
    local tail = vim.fn.fnamemodify(root, ":t")
    return tail ~= "" and tail or root
end

function M.prune()
    local alive = {}
    for _, t in ipairs(vim.api.nvim_list_tabpages()) do alive[t] = true end
    for t, s in pairs(tabpages) do
        if not alive[t] then
            if s.term and vim.api.nvim_buf_is_valid(s.term) then
                vim.api.nvim_buf_Delete(s.term, { force = true })
            end
            tabpages[t] = nil
        end
    end
end

function M.list()
    M.prune()
    return vim.api.nvim_list_tabpages()
end

function M.open(path)
    path = abs(path)
    if vim.fn.isdirectory(path) == 0 then
        return vim.notify("디렉토리가 아닙니다: " .. path, vim.log.levels.ERROR)
    end
    for _, tab in ipairs(M.list()) do
        if M.root(tab) == path then
            vim.api.nvim_set_current_tabpage(tab)
            return tab
        end
    end
    vim.cmd.tabnew()
    tcd(path)
    return vim.api.nvim_get_current_tabpage()
end

function M.close(tab)
    if #vim.api.nvim_list_tabpages() == 1 then
        return vim.notify("마지막 Workspace 는 닫을 수 없습니다", vim.log.levels.WARN)
    end
    vim.cmd(("tabclose %d"):format(vim.api.nvim_tabpage_get_number(resolve(tab))))
    M.prune()
end

local function trackable(buf)
    return vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ""
        and vim.api.nvim_buf_get_name(buf) ~= ""
end

function M.track(buf, tab)
    if not trackable(buf) then return end
    local bufs = M.get(tab).bufs
    if not vim.list_contains(bufs, buf) then table.insert(bufs, buf) end
end

function M.untrack(buf, tab)
    local bufs = M.get(tab).bufs
    for i, b in ipairs(bufs) do
        if b == buf then
            table.remove(bufs, i)
            return i
        end
    end
end

function M.buffers(tab)
    local s = M.get(tab)
    s.bufs = vim.tbl_filter(vim.api.nvim_buf_is_valid, s.bufs)
    return s.bufs
end

function M.go(i)
    local buf = M.buffers()[i]
    if buf then
        vim.api.nvim_set_current_buf(buf)
    end
end

function M.cycle(setp)
    local bufs = M.buffers()
    if #bufs == 0 then return end
    local cur, idex = vim.api.nvim_get_current_buf(), 0
    for i, b in ipairs(bufs) do
        if b == cur then idex = i end
    end
    vim.api.nvim_set_current_buf(bufs[(idx - 1 + step) % #bufs + 1])
end

--- 현재 Workspace 에서 buffer 를 닫는다. 다른 Workspace 가 쓰고 있으면 buffer 자체는 유지.
function M.close_buf(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local cur, shared = vim.api.nvim_get_current_tabpage(), false
    for tab, s in pairs(tabpages) do
        if tab ~= cur and vim.list_contains(s.bufs, buf) then shared = true end
    end
    if vim.bo[buf].modified and not shared then
        return vim.notify("저장되지 않은 변경 사항이 있습니다", vim.log.levels.WARN)
    end

    local idx = M.untrack(buf)
    local bufs = M.buffers()
    local nxt = bufs[math.min(idx or 1, #bufs)] or vim.api.nvim_create_buf(true, false)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == buf then vim.api.nvim_win_set_buf(win, nxt) end
    end
    if not shared then pcall(vim.api.nvim_buf_delete, buf, {}) end
    vim.cmd.redrawstatus()
end

---------------------------------------------------------------------------

function M.setup()
    vim.o.showtabline = 0 -- tabline 대신 floating 목록 + winbar 사용
    tcd(vim.fn.getcwd()) -- 시작 tab 도 고유 위치를 가지도록 고정

    local group = vim.api.nvim_create_augroup("workspace", { clear = true })
    local function au(ev, cb)
        vim.api.nvim_create_autocmd(ev, { group = group, callback = cb })
    end

    au({ "BufEnter", "BufFilePost" }, function(a)
        M.track(a.buf)
        vim.cmd.redrawstatus()
    end)
    au({ "BufDelete", "BufWipeout" }, function(a)
        for tab in pairs(tabpages) do M.untrack(a.buf, tab) end
    end)
    au("TabNewEntered", function() tcd(vim.fn.getcwd()) end) -- 어떤 방식으로 만든 tab 도 Workspace 화
    au("TabClosed", function() M.prune() end)

    for _, name in ipairs({ "winbar", "shell", "picker", "keymaps" }) do
        require("workspace." .. name).setup()
    end
end

return M
