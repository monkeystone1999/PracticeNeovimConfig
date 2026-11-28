-- ==========================================================================
-- Floating Terminal (<leader>tt / <leader>tT)
-- ==========================================================================
local float_term = {
    buf = nil,
    win = nil,
    cwd = nil,
}

local function get_float_term_config(target_dir)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.8)
    local row = math.floor(((vim.o.lines - vim.o.cmdheight) - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local title = " Terminal "
    if target_dir and target_dir ~= "" then
        title = " Terminal (" .. vim.fn.fnamemodify(target_dir, ":~") .. ") "
    end

    return {
        relative = "editor",
        row = row,
        col = col,
        width = math.max(width, 40),
        height = math.max(height, 10),
        style = "minimal",
        border = "rounded",
        title = title,
        title_pos = "center",
        footer = " <Esc> / [n] q : Close | <C-\\><C-n> : Normal Mode ",
        footer_pos = "center",
        zindex = 60,
    }
end

local function resolve_term_dir(use_current_file_dir)
    if use_current_file_dir then
        -- oil.nvim 버퍼인 경우 oil의 현재 디렉터리 사용
        if vim.bo.filetype == "oil" then
            local ok, oil = pcall(require, "oil")
            if ok then
                local oil_dir = oil.get_current_dir()
                if oil_dir and oil_dir ~= "" and vim.fn.isdirectory(oil_dir) == 1 then
                    return vim.fs.normalize(oil_dir)
                end
            end
        end

        local buf_name = vim.api.nvim_buf_get_name(0)
        if buf_name ~= "" then
            local file_dir = vim.fn.fnamemodify(buf_name, ":p:h")
            if file_dir ~= "" and vim.fn.isdirectory(file_dir) == 1 then
                return vim.fs.normalize(file_dir)
            end
        end
    end

    return vim.fs.normalize(vim.fn.getcwd(0))
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
--   false (<leader>tT) : 기존 플로팅 터미널 버퍼 재사용 (토글 동작, 작업 디렉터리 유지)
--   true  (<leader>tt) : 현재 파일이 위치한 디렉터리 기준으로 새 터미널 세션 열기
local function open_float_term(use_current_file_dir)
    -- 이미 창이 열려 있으면 닫기(토글)
    if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
        close_float_term()
        return
    end

    local target_dir = resolve_term_dir(use_current_file_dir)

    local need_new_term = use_current_file_dir
        or not float_term.buf
        or not vim.api.nvim_buf_is_valid(float_term.buf)
        or vim.bo[float_term.buf].buftype ~= "terminal"

    if need_new_term then
        -- 기존 숨겨진 터미널 버퍼가 있으면 정리 (좀비 터미널 프로세스 방지)
        if float_term.buf and vim.api.nvim_buf_is_valid(float_term.buf) then
            pcall(vim.api.nvim_buf_delete, float_term.buf, { force = true })
        end
        float_term.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[float_term.buf].bufhidden = "hide"
        float_term.cwd = target_dir
    end

    float_term.win = vim.api.nvim_open_win(float_term.buf, true, get_float_term_config(float_term.cwd))

    if need_new_term then
        vim.fn.jobstart({ vim.o.shell }, {
            term = true,
            cwd = target_dir,
            env = { PWD = target_dir },
        })
        bind_term_keymaps(float_term.buf)
    end

    vim.cmd("startinsert")
end

-- 창 크기 변경 시 열려 있는 플로팅 터미널 크기 자동 갱신
vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("FloatTermResize", { clear = true }),
    callback = function()
        if float_term.win and vim.api.nvim_win_is_valid(float_term.win) then
            vim.api.nvim_win_set_config(float_term.win, get_float_term_config(float_term.cwd))
        end
    end,
})

-- <leader>tT : 기존 플로팅 터미널 토글 (작업 상태 유지, 현재 cwd 기준)
vim.keymap.set({ "n", "t" }, "<leader>tT", function()
    open_float_term(false)
end, { silent = true, desc = "Floating Terminal 토글" })

-- <leader>tt : 현재 열린 파일의 폴더 경로에서 새 플로팅 터미널 열기
vim.keymap.set({ "n", "t" }, "<leader>tt", function()
    open_float_term(true)
end, { silent = true, desc = "Floating Terminal 새로 열기" })

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
