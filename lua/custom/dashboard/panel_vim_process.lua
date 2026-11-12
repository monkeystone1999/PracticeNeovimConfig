local M = {}
local vim_processes = require("custom.dashboard.find_vim_process")

local panel = {
    title = "Vim/Nvim Processes",
    content = {},
}
local buffer = nil
local process_list = {}

local callbacks = {
    close = function() end,
}

function M.set_callbacks(cbs)
    callbacks = vim.tbl_extend("force", callbacks, cbs or {})
end

-- 대상 PID의 Neovim RPC 소켓 경로 탐색 (/run/user/<uid>/nvim.<pid>.0 등)
local function find_nvim_socket(pid, ui_pid)
    local runtime_dir = vim.env.XDG_RUNTIME_DIR or ("/run/user/" .. (vim.uv or vim.loop).getuid())
    local candidates = {
        string.format("%s/nvim.%d.0", runtime_dir, pid),
    }
    if ui_pid then
        table.insert(candidates, string.format("%s/nvim.%d.0", runtime_dir, ui_pid))
    end
    for _, path in ipairs(candidates) do
        if (vim.uv or vim.loop).fs_stat(path) then
            return path
        end
    end
    return nil
end

-- 백그라운드/중지된(BG/STOPPED) Neovim 프로세스의 세션을 현재 창으로 가져오고 기존 프로세스 정리
local function takeover_background_process(proc)
    local pid = proc.pid
    local ui_pid = proc.ui_pid

    -- 1) 만약 Ctrl+Z(T 상태)로 멈춰 있다면 일시적으로 깨워서(SIGCONT) 세션 저장이 가능하게 함
    if proc.stat and proc.stat:find("T") then
        if ui_pid then
            os.execute(string.format("kill -CONT %d 2>/dev/null", ui_pid))
        end
        os.execute(string.format("kill -CONT %d 2>/dev/null", pid))
        vim.wait(80)
    end

    -- 2) 대상 Neovim 소켓이 열려 있다면 임시 세션 스냅샷을 저장하고 원격 종료 요청
    local temp_session = string.format("%s/takeover_%d.vim", vim.fn.stdpath("state"), pid)
    local sock_path = find_nvim_socket(pid, ui_pid)
    local session_saved = false

    if sock_path then
        local ok_conn, chan = pcall(vim.fn.sockconnect, "pipe", sock_path, { rpc = true })
        if ok_conn and chan and chan > 0 then
            pcall(vim.rpcrequest, chan, "nvim_command", "silent! mksession! " .. vim.fn.fnameescape(temp_session))
            pcall(vim.rpcnotify, chan, "nvim_command", "qa!")
            pcall(vim.fn.chanclose, chan)
            vim.wait(100)
            session_saved = (vim.fn.filereadable(temp_session) == 1)
        end
    end

    -- 3) 아직 남아 있는 백그라운드 프로세스가 있다면 정리
    if ui_pid then
        os.execute(string.format("kill -TERM %d 2>/dev/null", ui_pid))
    end
    os.execute(string.format("kill -TERM %d 2>/dev/null", pid))

    -- 4) 대시보드를 닫고 현재 Neovim에서 해당 작업 디렉터리 및 세션 복구 (Foreground 전환)
    callbacks.close()

    if proc.cwd and proc.cwd ~= "" and proc.cwd ~= "(unknown)" then
        pcall(vim.cmd.tcd, proc.cwd)
    end

    if session_saved then
        vim.cmd("silent! %bdelete!")
        vim.cmd("silent! source " .. vim.fn.fnameescape(temp_session))
        vim.fn.delete(temp_session)
    end

    vim.notify(
        string.format("PID %d (%s) 프로세스를 현재 창(Foreground)으로 가져왔습니다.", pid, proc.cwd),
        vim.log.levels.INFO,
        { title = "Vim/Nvim Processes" }
    )
end

function M.get_content()
    process_list = vim_processes.get_processes()
    if #process_list == 0 then
        panel.content = { " (현재 감지된 다른 Vim/Nvim 프로세스가 없습니다)" }
    else
        local lines = {}
        for _, proc in ipairs(process_list) do
            table.insert(lines, proc.display)
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

    -- r: 프로세스 목록 수동 새로고침
    vim.keymap.set("n", "r", function()
        M.refresh()
    end, opts)

    -- Enter(<CR>):
    -- 1) 이미 Foreground([FG]) 상태면 동작하지 않고 nvim-notify 경고 알림 표시
    -- 2) Background/Stopped([BG]/[STOPPED]) 상태면 현재 창으로 세션 가져오기
    vim.keymap.set("n", "<CR>", function()
        local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
        local proc = process_list[cursor_row]
        if not proc then
            return
        end

        if proc.is_fg then
            vim.notify(
                string.format(
                    "PID %d (%s) 프로세스는 이미 다른 터미널의 Foreground에서 실행 중입니다.",
                    proc.pid,
                    proc.cwd
                ),
                vim.log.levels.WARN,
                { title = "Vim/Nvim Processes" }
            )
            return
        end

        takeover_background_process(proc)
    end, opts)
end

function M.setup()
    vim_processes.setup()
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
        footer = " r:Refresh, Enter:Foreground (BG/Stopped only) ",
        footer_pos = "center",
    }
    return { win_config, buffer }
end

return M
