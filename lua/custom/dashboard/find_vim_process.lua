local M = {}

local is_win = false

local function find_vim_processes_win()
    local results = {}
    local my_pid = vim.fn.getpid()
    local handle = io.popen(
        'powershell -NoProfile -Command "Get-Process nvim,vim -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, MainWindowHandle | ConvertTo-Json -Compress"'
    )
    if not handle then
        return results
    end
    local output = handle:read("*a")
    handle:close()

    if not output or output == "" then
        return results
    end

    local ok, parsed = pcall(vim.json.decode, output)
    if not ok or not parsed then
        return results
    end

    -- 단일 객체인 경우 배열로 감싸기
    if parsed.Id then
        parsed = { parsed }
    end

    for _, item in ipairs(parsed) do
        local pid = tonumber(item.Id)
        if pid and pid ~= my_pid then
            local is_fg = (tonumber(item.MainWindowHandle) or 0) ~= 0
            local state_tag = is_fg and "FG" or "BG"
            table.insert(results, {
                pid = pid,
                ui_pid = nil,
                stat = state_tag,
                tty = "win",
                is_fg = is_fg,
                cwd = "",
                cmd = item.ProcessName or "nvim",
                display = string.format(" • [%s] PID:%-6d : %s", state_tag, pid, item.ProcessName or "nvim"),
            })
        end
    end
    return results
end

local function find_vim_processes_linux()
    local results = {}
    local my_pid = vim.fn.getpid()

    local handle = io.popen("ps -eo pid=,ppid=,stat=,tty=,comm=,args=")
    if not handle then
        return results
    end

    local raw_procs = {}
    local by_pid = {}

    for line in handle:lines() do
        local pid_s, ppid_s, stat, tty, comm, args =
            line:match("^%s*(%d+)%s+(%d+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.*)$")
        if pid_s and (comm == "nvim" or comm == "vim") then
            local pid = tonumber(pid_s)
            local ppid = tonumber(ppid_s)
            local entry = {
                pid = pid,
                ppid = ppid,
                stat = stat,
                tty = tty,
                comm = comm,
                args = args,
            }
            table.insert(raw_procs, entry)
            by_pid[pid] = entry
        end
    end
    handle:close()

    -- 현재 실행 중인 Neovim 자신(my_pid) 및 그 부모 UI 프로세스(my_ppid) 제외
    local my_proc = by_pid[my_pid]
    local my_ppid = my_proc and my_proc.ppid or nil

    for _, proc in ipairs(raw_procs) do
        local is_self = (proc.pid == my_pid) or (my_ppid and proc.pid == my_ppid)
        -- 부모가 nvim인 자식(--embed) 프로세스가 따로 있다면, 실제 세션/소켓을 가진 자식(--embed) 기준으로 하나로 묶음
        local has_nvim_child = false
        for _, other in ipairs(raw_procs) do
            if other.ppid == proc.pid then
                has_nvim_child = true
                break
            end
        end

        if not is_self and not has_nvim_child then
            local parent_nvim = by_pid[proc.ppid]
            local effective_stat = (parent_nvim and parent_nvim.stat) or proc.stat
            local effective_tty = (parent_nvim and parent_nvim.tty) or proc.tty

            -- STAT에 '+'가 포함되어 있으면 터미널의 Foreground 프로세스 그룹에서 활성 실행 중
            local is_fg = effective_stat:find("%+") ~= nil
            local state_tag = is_fg and "FG" or (effective_stat:find("T") and "STOPPED" or "BG")

            local cwd = (vim.uv or vim.loop).fs_readlink("/proc/" .. proc.pid .. "/cwd") or "(unknown)"

            table.insert(results, {
                pid = proc.pid,
                ui_pid = parent_nvim and parent_nvim.pid or nil,
                stat = effective_stat,
                tty = effective_tty,
                is_fg = is_fg,
                cwd = cwd,
                cmd = proc.args,
                display = string.format(
                    " • [%-7s] PID:%-6d (%s) : %s",
                    state_tag,
                    proc.pid,
                    effective_tty,
                    cwd
                ),
            })
        end
    end

    return results
end

function M.setup()
    is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

-- 상세 프로세스 메타데이터 배열 반환
function M.get_processes()
    if is_win then
        return find_vim_processes_win()
    else
        return find_vim_processes_linux()
    end
end

-- 패널 표시용 문자열 배열 반환
function M.get_info()
    local procs = M.get_processes()
    local lines = {}
    for _, p in ipairs(procs) do
        table.insert(lines, p.display)
    end
    return lines
end

return M
