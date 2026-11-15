-- ==========================================================================
-- Floating Terminal (<leader>tt / <leader>tT)
-- ==========================================================================
local float_term = {
    buf = nil,
    win = nil,
}

local function get_float_term_config()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.8)
    local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    return {
        relative = "editor",
        row = row,
        col = col,
        width = math.max(width, 40),
        height = math.max(height, 10),
        style = "minimal",
        border = "rounded",
        title = " Terminal ",
        title_pos = "center",
        footer = " <Esc> / [n] q : Close | <C-\\><C-n> : Normal Mode ",
        footer_pos = "center",
        zindex = 60,
    }
end

local function close_float_term()
    if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
        vim.api.nvim_win_close(float_term.win, true)
        float_term.win = nil
    end
end

local function bind_term_keymaps(buf)
    local opts = { buffer = buf, silent = true, nowait = true }

    -- 터미널 모드(t) 및 노멀 모드(n)에서 <Esc>를 누르면 즉시 창 닫기
    vim.keymap.set({ "t", "n" }, "<Esc>", function()
        close_float_term()
    end, opts)

    -- 노멀 모드(n)에서 q 를 누르면 즉시 창 닫기
    vim.keymap.set("n", "q", function()
        close_float_term()
    end, opts)
end

-- force_new_or_cwd:
--   false (<leader>tt) : 기존 플로팅 터미널 버퍼 재사용 (토글 동작, 작업 디렉터리 유지)
--   true  (<leader>tT) : 현재 파일이 위치한 디렉터리 기준으로 새 터미널 세션 열기
local function open_float_term(use_current_file_dir)
    -- 이미 창이 열려 있으면 닫기(토글)
    if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
        close_float_term()
        return
    end

    local target_dir = vim.fn.getcwd(0)
    if use_current_file_dir then
        local file_dir = vim.fn.expand("%:p:h")
        if file_dir ~= "" and vim.fn.isdirectory(file_dir) == 1 then
            target_dir = file_dir
        end
    end

    local need_new_term = use_current_file_dir
        or not float_term.buf
        or not vim.api.nvim_buf_is_valid(float_term.buf)
        or vim.bo[float_term.buf].buftype ~= "terminal"

    if need_new_term then
        float_term.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[float_term.buf].bufhidden = "hide"
    end

    float_term.win = vim.api.nvim_open_win(float_term.buf, true, get_float_term_config())

    if need_new_term then
        vim.fn.termopen(vim.o.shell, { cwd = target_dir })
        bind_term_keymaps(float_term.buf)
    end

    vim.cmd("startinsert")
end

-- 창 크기 변경 시 열려 있는 플로팅 터미널 크기 자동 갱신
vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("FloatTermResize", { clear = true }),
    callback = function()
        if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
            vim.api.nvim_win_set_config(float_term.win, get_float_term_config())
        end
    end,
})

-- <leader>tt : 기존 플로팅 터미널 토글 (작업 상태 유지, 현재 cwd 기준)
vim.keymap.set({ "n", "t" }, "<leader>tt", function()
    open_float_term(false)
end, { silent = true, desc = "Floating Terminal 토글 (CWD)" })

-- <leader>tT : 현재 열린 파일의 폴더 경로에서 새 플로팅 터미널 열기
vim.keymap.set({ "n", "t" }, "<leader>tT", function()
    open_float_term(true)
end, { silent = true, desc = "Floating Terminal 새로 열기 (현재 파일 경로)" })

-- ==========================================================================
-- 읽기 전용 / 보조 유틸리티 창에서 q 및 <Esc> 로 즉시 닫기
-- ==========================================================================
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CloseWithQAndEsc", { clear = true }),
    pattern = {
        "help",
        "qf",
        "ClangdAST",
        "ClangdTypeHierarchy",
        "notify",
        "lspinfo",
        "checkhealth",
        "man",
    },
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true, nowait = true }
        vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
        vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", opts)
    end,
})
