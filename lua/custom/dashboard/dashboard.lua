local M = {}

local Entry = require("custom.bases.entry")
local workspace = require("custom.bases.workspace")

local project_panel = require("custom.dashboard.panel_project")
local vim_panel = require("custom.dashboard.panel_vim_process")
local workspace_panel = require("custom.dashboard.panel_session_list")

local current_size = ""
-- full_screen, half_screen, quarter_screen

-- HalfScreen 우측에 표시할 패널 상태 ("vim" 또는 "workspace")
local half_right_mode = "vim"

-- 현재 열려 있는 대시보드 플로팅 윈도우 ID 목록
-- full_screen : [1] = 좌상(vim), [2] = 좌하(workspace), [3] = 우(project)
-- half_screen : [1] = 좌(project), [2] = 우(vim 또는 workspace)
-- quarter_screen : [1] = 전체(project)
local active_wins = {}

-- 각 대시보드 윈도우 ID가 원래 담고 있던 대시보드 전용 버퍼 매핑 (win_id -> buf_id)
local win_panel_buf = {}

-- 대시보드 소속 버퍼 집합 (buf_id -> true)
local dashboard_bufs = {}

-- FullScreen에서 우측(project) -> 좌측으로 이동할 때 마지막에 있었던 좌측 창(1 또는 2) 기억
local last_left_idx = 1

local function is_dashboard_open()
    for _, win in ipairs(active_wins) do
        if vim.api.nvim_win_is_valid(win) then
            return true
        end
    end
    return false
end

local function is_active_dashboard_win(win)
    for _, w in ipairs(active_wins) do
        if w == win then
            return true
        end
    end
    return false
end

-- 플로팅 창이 아닌 바닥의 기본 에디터 창(normal window) 찾기
local function get_base_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
            return win
        end
    end
    return nil
end

local function close_active_wins()
    for _, win in ipairs(active_wins) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    active_wins = {}
    win_panel_buf = {}
end

local function close_dashboard()
    current_size = ""
    close_active_wins()
end

local function focus_win(win)
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    end
end

-- 위치 기반(상/하/좌/우) 윈도우 포커스 이동
local function move_win(dir)
    local cur_win = vim.api.nvim_get_current_win()

    if current_size == "full_screen" then
        local win_top_left = active_wins[1]
        local win_bot_left = active_wins[2]
        local win_right = active_wins[3]

        if cur_win == win_top_left then
            if dir == "down" then
                last_left_idx = 2
                focus_win(win_bot_left)
            elseif dir == "right" then
                last_left_idx = 1
                focus_win(win_right)
            end
        elseif cur_win == win_bot_left then
            if dir == "up" then
                last_left_idx = 1
                focus_win(win_top_left)
            elseif dir == "right" then
                last_left_idx = 2
                focus_win(win_right)
            end
        elseif cur_win == win_right then
            if dir == "left" then
                focus_win(active_wins[last_left_idx] or win_top_left)
            end
        end
    elseif current_size == "half_screen" then
        local win_left = active_wins[1]
        local win_right = active_wins[2]

        if cur_win == win_left and dir == "right" then
            focus_win(win_right)
        elseif cur_win == win_right and dir == "left" then
            focus_win(win_left)
        end
    end
end

local half_screen
local quarter_screen

local function toggle_half_panel()
    if current_size ~= "half_screen" then
        return
    end
    if half_right_mode == "vim" then
        half_right_mode = "workspace"
    else
        half_right_mode = "vim"
    end
    half_screen()
end

local function bind_panel_keymaps(buf)
    local opts = { buffer = buf, silent = true, nowait = true }

    -- HalfScreen 우측 패널 토글 ('t')
    vim.keymap.set("n", "t", toggle_half_panel, opts)

    -- QuarterScreen에서 서브 패널(vim/workspace) 열었을 때 'q' 또는 '<BS>'로 Project 패널 복귀/종료
    if buf ~= project_panel.get_buf() then
        vim.keymap.set("n", "q", function()
            if current_size == "quarter_screen" then
                quarter_screen()
            else
                close_dashboard()
            end
        end, opts)
        vim.keymap.set("n", "<BS>", function()
            if current_size == "quarter_screen" then
                quarter_screen()
            end
        end, opts)
    end

    -- 방향키 및 위치 기반 창 이동 (<Left>/<Right>/<Up>/<Down>, <C-h/j/k/l>, <C-w>h/j/k/l)
    local nav_keys = {
        left  = { "<Left>", "<C-h>", "<C-w>h", "<C-w><Left>" },
        right = { "<Right>", "<C-l>", "<C-w>l", "<C-w><Right>" },
        up    = { "<Up>", "<C-k>", "<C-w>k", "<C-w><Up>" },
        down  = { "<Down>", "<C-j>", "<C-w>j", "<C-w><Down>" },
    }
    for dir, keys in pairs(nav_keys) do
        for _, key in ipairs(keys) do
            vim.keymap.set("n", key, function()
                move_win(dir)
            end, opts)
        end
    end
end

local function open_panel(panel_info, enter)
    local win_config, panel_buf = panel_info[1], panel_info[2]
    -- Telescope(기본 zindex 50) 및 Oil float(기본 zindex 45)가 대시보드 위에 뜨도록 zindex를 10으로 설정
    win_config.zindex = win_config.zindex or 10
    dashboard_bufs[panel_buf] = true
    bind_panel_keymaps(panel_buf)
    local win = vim.api.nvim_open_win(panel_buf, enter or false, win_config)
    table.insert(active_wins, win)
    win_panel_buf[win] = panel_buf
    return win
end

-- FullScreen (cols >= 160):
-- 좌측 50%에 vim_panel(상) + workspace_panel(하), 우측 50%에 project_panel(전체 높이)
local function full_screen()
    close_active_wins()

    local cols = vim.o.columns
    local lines = vim.o.lines - vim.o.cmdheight

    -- 좌/우 50% 외곽 너비 계산 (border 2칸 감안하여 내부 width 산출)
    local left_outer_w = math.floor(cols / 2)
    local right_outer_w = cols - left_outer_w
    local left_w = math.max(left_outer_w - 2, 10)
    local right_w = math.max(right_outer_w - 2, 10)

    -- 좌측 상/하 50% 외곽 높이 계산 (border 2줄 감안하여 내부 height 산출)
    local top_outer_h = math.floor(lines / 2)
    local bot_outer_h = lines - top_outer_h
    local top_h = math.max(top_outer_h - 2, 3)
    local bot_h = math.max(bot_outer_h - 2, 3)

    -- 우측 전체 높이
    local full_h = math.max(lines - 2, 5)

    -- 1) 좌측 상단: vim_panel (row = 0, col = 0)
    local v_panel = vim_panel.get_panel(0, 0, left_w, top_h)
    open_panel(v_panel, false)

    -- 2) 좌측 하단: workspace_panel (row = top_outer_h, col = 0)
    local w_panel = workspace_panel.get_panel(top_outer_h, 0, left_w, bot_h)
    open_panel(w_panel, false)

    -- 3) 우측 전체: project_panel (row = 0, col = left_outer_w, 포커스 진입)
    local p_panel = project_panel.get_panel(0, left_outer_w, right_w, full_h)
    open_panel(p_panel, true)
end

-- HalfScreen (80 <= cols < 160):
-- 좌측 50%에 project_panel 고정, 우측 50%에 vim_panel 또는 workspace_panel 단독 렌더링 ('t' 키로 토글)
half_screen = function()
    local cur_win = vim.api.nvim_get_current_win()
    local focus_right = (active_wins[2] ~= nil and cur_win == active_wins[2])

    close_active_wins()

    local cols = vim.o.columns
    local lines = vim.o.lines - vim.o.cmdheight

    -- 좌/우 50% 외곽 너비 및 전체 높이 계산 (border 2칸/2줄 감안)
    local left_outer_w = math.floor(cols / 2)
    local right_outer_w = cols - left_outer_w
    local left_w = math.max(left_outer_w - 2, 10)
    local right_w = math.max(right_outer_w - 2, 10)
    local full_h = math.max(lines - 2, 5)

    -- 1) 좌측 50%: project_panel 고정 (현재 half_right_mode를 넘겨 토글될 대상 버퍼명을 단축키와 표시)
    local p_panel = project_panel.get_half_panel(0, 0, left_w, full_h, half_right_mode)
    open_panel(p_panel, not focus_right)

    -- 2) 우측 50%: half_right_mode 에 따라 vim_panel 또는 workspace_panel 렌더링 + 하단 footer에 토글 안내 표시
    local right_panel
    if half_right_mode == "vim" then
        right_panel = vim_panel.get_panel(0, left_outer_w, right_w, full_h)
        right_panel[1].footer = " [t] -> Workspaces "
        right_panel[1].footer_pos = "center"
    else
        right_panel = workspace_panel.get_panel(0, left_outer_w, right_w, full_h)
        right_panel[1].footer = " [t] -> Vim/Nvim Processes "
        right_panel[1].footer_pos = "center"
    end
    open_panel(right_panel, focus_right)
end

-- QuarterScreen (cols < 80 또는 극소 창):
-- 부가 패널을 모두 숨기고 project_panel 하나만 화면 전체에 꽉 채움
quarter_screen = function()
    close_active_wins()

    local cols = vim.o.columns
    local lines = vim.o.lines - vim.o.cmdheight

    -- rounded border(상하 2줄, 좌우 2칸)를 감안한 내부 크기 계산
    local width = math.max(cols - 2, 10)
    local height = math.max(lines - 2, 5)

    local p_panel = project_panel.get_quarter_panel(0, 0, width, height)
    open_panel(p_panel, true)
end

local function apply_layout()
    local cols = vim.o.columns
    local lines = vim.o.lines

    if cols < 80 or lines < 15 then
        if current_size == "quarter_screen" then
            return
        end
        current_size = "quarter_screen"
        quarter_screen()
    elseif cols >= 80 and cols < 160 then
        if current_size == "half_screen" then
            return
        end
        current_size = "half_screen"
        half_screen()
    else
        if current_size == "full_screen" then
            return
        end
        current_size = "full_screen"
        full_screen()
    end
end

function M.open()
    current_size = ""
    apply_layout()
end

function M.close()
    close_dashboard()
end

function M.toggle()
    if is_dashboard_open() then
        close_dashboard()
    else
        M.open()
    end
end

local is_setup = false

function M.setup()
    vim_panel.setup()
    workspace_panel.setup()
    project_panel.setup()

    vim_panel.set_callbacks({
        close = close_dashboard,
    })

    workspace_panel.set_callbacks({
        close = close_dashboard,
    })

    -- project_panel 액션 콜백 연결
    project_panel.set_callbacks({
        close = close_dashboard,
        toggle_half = toggle_half_panel,
        open_quarter_vim = function()
            if current_size ~= "quarter_screen" then return end
            close_active_wins()
            local width = math.max(vim.o.columns - 2, 10)
            local height = math.max(vim.o.lines - vim.o.cmdheight - 2, 5)
            local v_panel = vim_panel.get_panel(0, 0, width, height)
            v_panel[1].footer = " [q/<BS>] -> Back to Project "
            v_panel[1].footer_pos = "center"
            open_panel(v_panel, true)
        end,
        open_quarter_ws = function()
            if current_size ~= "quarter_screen" then return end
            close_active_wins()
            local width = math.max(vim.o.columns - 2, 10)
            local height = math.max(vim.o.lines - vim.o.cmdheight - 2, 5)
            local w_panel = workspace_panel.get_panel(0, 0, width, height)
            w_panel[1].footer = " [q/<BS>] -> Back to Project "
            w_panel[1].footer_pos = "center"
            open_panel(w_panel, true)
        end,
    })

    is_setup = true

    -- 언제든 대시보드를 토글할 수 있는 사용자 명령어(:Dashboard) 및 단축키(<leader>db) 등록
    vim.api.nvim_create_user_command("Dashboard", function()
        M.toggle()
    end, { desc = "Toggle Dashboard" })

    vim.keymap.set("n", "<leader>db", function()
        M.toggle()
    end, { silent = true, desc = "Toggle Dashboard" })

    -- 핵심 보호 로직:
    -- 어느 패널에서든 e, f, g, <leader>ff, <leader>fg, <leader>e 등을 통해 파일이 선택되어
    -- 대시보드 플로팅 창(active_wins) 내부에 일반 파일 버퍼가 열리는 순간 이를 감지하고,
    -- 해당 파일과 커서 위치를 바닥의 메인 에디터 창(base_win)으로 옮긴 뒤 대시보드를 닫음!
    -- (반대로 Telescope/Oil에서 <Esc>로 취소하면 버퍼가 바뀌지 않으므로 대시보드가 그대로 유지됨)
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
        callback = function()
            if not is_dashboard_open() then
                return
            end

            local cur_win = vim.api.nvim_get_current_win()
            if not is_active_dashboard_win(cur_win) then
                return
            end

            local new_buf = vim.api.nvim_win_get_buf(cur_win)
            if dashboard_bufs[new_buf] then
                return
            end

            vim.schedule(function()
                if not vim.api.nvim_win_is_valid(cur_win) then
                    return
                end
                local target_buf = vim.api.nvim_win_get_buf(cur_win)
                if dashboard_bufs[target_buf] then
                    return
                end

                -- Live Grep 등으로 이동한 줄/칸 커서 위치 보존
                local cursor = vim.api.nvim_win_get_cursor(cur_win)

                -- 대시보드 패널 창에는 원래 패널 버퍼를 복구해 둠
                local orig_panel_buf = win_panel_buf[cur_win]
                if orig_panel_buf and vim.api.nvim_buf_is_valid(orig_panel_buf) then
                    pcall(vim.api.nvim_win_set_buf, cur_win, orig_panel_buf)
                end

                -- 바닥의 메인 에디터 창에 선택한 파일을 열고 커서 위치 복원 후 대시보드 닫기
                local base_win = get_base_win()
                close_dashboard()

                if base_win and vim.api.nvim_win_is_valid(base_win) then
                    vim.api.nvim_set_current_win(base_win)
                    vim.api.nvim_win_set_buf(base_win, target_buf)
                    pcall(vim.api.nvim_win_set_cursor, base_win, cursor)
                end
            end)
        end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            local entry_typ, path = Entry.get_state(), Entry.get_abs_path()
            if entry_typ == "empty" then
                M.open()
            elseif entry_typ == "dir" and path then
                -- nvim . 등 디렉터리 지정 시작 시: 해당 경로로 이동( 및 등록된 워크스페이스 연동) 후 대시보드 유지
                pcall(vim.cmd.tcd, path)
                local matched_ws = workspace.find_by_path(path)
                if matched_ws then
                    workspace.current_workspace = matched_ws
                end
                vim.schedule(function()
                    M.open()
                end)
            elseif entry_typ == "file" then
            end
        end,
    })

    -- 1) 기존 레이아웃 모드 전환용 VimResized (current_size 조건문 그대로 유지)
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if not is_dashboard_open() then
                return
            end
            apply_layout()
        end,
    })

    -- 2) 별도의 윈도우 크기 갱신용 VimResized (창이 열려 있고 같은 레이아웃 모드 내일 때 창 크기만 조정)
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if not is_dashboard_open() then
                return
            end

            local cols = vim.o.columns
            local lines = vim.o.lines - vim.o.cmdheight

            if current_size == "full_screen" and #active_wins == 3 then
                local left_outer_w = math.floor(cols / 2)
                local right_outer_w = cols - left_outer_w
                local left_w = math.max(left_outer_w - 2, 10)
                local right_w = math.max(right_outer_w - 2, 10)

                local top_outer_h = math.floor(lines / 2)
                local bot_outer_h = lines - top_outer_h
                local top_h = math.max(top_outer_h - 2, 3)
                local bot_h = math.max(bot_outer_h - 2, 3)
                local full_h = math.max(lines - 2, 5)

                if vim.api.nvim_win_is_valid(active_wins[1]) then
                    vim.api.nvim_win_set_config(active_wins[1], { relative = "editor", row = 0, col = 0, width = left_w, height = top_h })
                end
                if vim.api.nvim_win_is_valid(active_wins[2]) then
                    vim.api.nvim_win_set_config(active_wins[2], { relative = "editor", row = top_outer_h, col = 0, width = left_w, height = bot_h })
                end
                if vim.api.nvim_win_is_valid(active_wins[3]) then
                    vim.api.nvim_win_set_config(active_wins[3], { relative = "editor", row = 0, col = left_outer_w, width = right_w, height = full_h })
                end
            elseif current_size == "half_screen" and #active_wins == 2 then
                local left_outer_w = math.floor(cols / 2)
                local right_outer_w = cols - left_outer_w
                local left_w = math.max(left_outer_w - 2, 10)
                local right_w = math.max(right_outer_w - 2, 10)
                local full_h = math.max(lines - 2, 5)

                if vim.api.nvim_win_is_valid(active_wins[1]) then
                    vim.api.nvim_win_set_config(active_wins[1], { relative = "editor", row = 0, col = 0, width = left_w, height = full_h })
                end
                if vim.api.nvim_win_is_valid(active_wins[2]) then
                    vim.api.nvim_win_set_config(active_wins[2], { relative = "editor", row = 0, col = left_outer_w, width = right_w, height = full_h })
                end
            elseif current_size == "quarter_screen" and #active_wins == 1 then
                local width = math.max(cols - 2, 10)
                local height = math.max(lines - 2, 5)

                if vim.api.nvim_win_is_valid(active_wins[1]) then
                    vim.api.nvim_win_set_config(active_wins[1], { relative = "editor", row = 0, col = 0, width = width, height = height })
                end
            end
        end,
    })
end

return M
