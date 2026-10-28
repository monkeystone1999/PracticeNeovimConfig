-- Workspace 별 독립 shell + .env 주입
local ws = require("workspace")
local ui = require("workspace.ui")

local M = { env_file = ".env" }

local function start(opts)
    if vim.fn.has("nvim-0.11") == 1 then
        opts.term = true
        return vim.fn.jobstart(vim.o.shell, opts)
    end
    return vim.fn.termopen(vim.o.shell, opts)
end

--- 현재 tab 에서 buf 를 보여주는 window
local function visible(buf)
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then return end
    local cur = vim.api.nvim_get_current_tabpage()
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_get_tabpage(win) == cur then return win end
    end
end

--- 현재 Workspace 의 shell 을 floating 으로 띄운다 (없으면 생성)
function M.show()
    local s = ws.get()
    local fresh = not (s.term and vim.api.nvim_buf_is_valid(s.term))
    if fresh then s.term = vim.api.nvim_create_buf(false, false) end
    local buf = s.term

    local win = visible(buf)
    if win then
        vim.api.nvim_set_current_win(win)
    else
        ui.float(buf, { title = " " .. ws.name() .. " " })
    end

    if fresh then -- float 가 현재 window 이므로 현재 buffer == buf
        start({
            cwd = ws.root(),
            on_exit = function()
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
                end)
            end,
        })
        vim.keymap.set("t", "<Esc><Esc>", M.toggle, { buffer = buf })
        vim.keymap.set("n", "q", M.toggle, { buffer = buf })
    end
    vim.cmd.startinsert()
    return buf
end

function M.toggle()
    local win = visible(ws.get().term)
    if win then vim.api.nvim_win_close(win, true) else M.show() end
end

--- Workspace 위치로 cd -> .env 주입 -> 명령 실행 (같은 shell 에서 환경변수 유지)
function M.run(cmd)
    local env = vim.fn.shellescape(M.env_file)
    local line = ("cd %s && { [ -f %s ] && export $(grep -v '^#' %s | xargs); %s; }\n"):format(
        vim.fn.shellescape(ws.root()), env, env, cmd
    )
    ws.get().last = cmd
    local buf = M.show()
    vim.fn.chansend(vim.bo[buf].channel, line)
end

function M.rerun()
    local last = ws.get().last
    if last then M.run(last) else vim.notify("실행한 명령이 없습니다", vim.log.levels.INFO) end
end

function M.setup()
    vim.api.nvim_create_user_command("WsRun", function(c) M.run(c.args) end, { nargs = "+", complete = "shellcmd" })
    vim.api.nvim_create_user_command("WsShell", M.toggle, {})
end

return M
