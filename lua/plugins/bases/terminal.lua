local width = math.floor(vim.o.columns * 0.8)
local height = math.floor(vim.o.lines * 0.8)
local TerminalConfig = {
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
}


local global_terminal_buf
local global_terminal_win
local temp_terminal_buf
local temp_terminal_win
local terminal_config = {
    relative = "editor",
    width = TerminalConfig.width,
    height = TerminalConfig.height,
    row = TerminalConfig.row,
    col =
        TerminalConfig.col,
    style = "minimal",
    border = "rounded"
}

local function add_global_terminal()
    local new_global_buf = vim.api.nvim_create_buf(false, true)
    global_terminal_buf = { global_terminal_buf, new_global_buf }
    global_terminal_win = vim.api.nvim_open_win(new_global_buf, true, terminal_config)
    local cwd = vim.fn.getcwd()
    vim.api.nvim_buf_call(new_global_buf, function()
        vim.fn.jobstart(vim.o.shell, {
            term = true,
            cwd = cwd
        })
    end)
    vim.cmd("startinsert")
end

local function close_valid_win()
    -- global 은 win 만 하는 이유는 buffer 는 보존이 된채 창만 닫혀야하기 때문이다
    if vim.api.nvim_win_is_valid(global_terminal_win) then
        vim.api.nvim_win_close(global_terminal_win, true)
    end
    if vim.api.nvim_win_is_valid(temp_terminal_win) then
        vim.api.nvim_win_close(temp_terminal_win, true)
    end
    if vim.api.nvim_buf_is_valid(temp_terminal_buf) then
        vim.api.nvim_buf_delete(temp_terminal_buf, {
            force = true
        })
    end
end
local function make_temp()
    temp_terminal_buf = vim.api.nvim_create_buf(false, true)
    temp_terminal_win = vim.api.nvim_open_win(temp_terminal_buf, true, terminal_config)
    local cwd = vim.fn.getcwd()
    vim.api.nvim_buf_call(temp_terminal_buf, function()
        vim.fn.jobstart(vim.o.shell, {
            term = true,
            cwd = cwd
        })
    end)
    vim.cmd("startinsert")
end


local function toggled_terminal()
    close_valid_win()
    if vim.api.nvim_win_is_valid(global_terminal_win) then
        vim.api.nvim_win_close(global_terminal_win, true)
        return
    else
        make_temp()
    end
end

local M = {}
function M.setup()
    vim.keymap.set("n", "<leader>tT", add_global_terminal)
    vim.keymap.set("n", "<leader>tt", toggled_terminal
        ,
        { buf = 0, silent = true })
end

return M
