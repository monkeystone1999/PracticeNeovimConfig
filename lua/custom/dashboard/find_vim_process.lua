local M = {}

local is_win = nil

local function find_vim_process_win()
    local handle = io.popen(
        'powershell -NoProfile -Command "Get-Process nvim,.vim -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, CPU"')
    if handle then
        for line in handle:lines() do
            if line:match("%d+") and not line:match("ProcessName") then
                handle:close()
                return line
            end
        end
    end
    handle:close()
end
local function find_vim_process_linux()
    local handle = io.popen("ps -ef | grep -E '[n]vim|[v]im'")
    if handle then
        for line in handle:lines() do
            handle:close()
            return line
        end
    end
    handle:close()
end

function M.setup()
    is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

function M.get_info()
    local processes = {}
    if is_win then
        table.insert(processes, "    > " .. find_vim_process_win())
    else
        table.insert(processes, "    > " .. find_vim_process_linux())
    end
    return processes
end

return M
