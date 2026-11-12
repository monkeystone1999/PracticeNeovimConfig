local M = {}

local buffer = nil
local first_item_row = 1
local first_item_col = 0
local current_lines = {}

local callbacks = {
    close = function() end,
    toggle_half = function() end,
    open_quarter_vim = function() end,
    open_quarter_ws = function() end,
}

local panel = {
    title = "Project",
    content = {
        "[e] File Explorer (Oil)",
        "[f] Find Files",
        "[g] Live Grep",
        "[q] Quick Dashboard",
    },
}

-- 각 단축키에 대응하는 실제 동작 정의
local actions = {
    e = function()
        require("oil").open_float()
    end,
    f = function()
        require("telescope.builtin").find_files()
    end,
    g = function()
        require("telescope.builtin").live_grep()
    end,
    q = function()
        callbacks.close()
        vim.cmd("confirm qa")
    end,
    t = function()
        callbacks.toggle_half()
    end,
    p = function()
        callbacks.open_quarter_vim()
    end,
    w = function()
        callbacks.open_quarter_ws()
    end,
}

function M.set_callbacks(cbs)
    callbacks = vim.tbl_extend("force", callbacks, cbs or {})
end

-- 주어진 너비(width)와 높이(height)의 정가운데에 콘텐츠를 배치
local function center_lines(lines, width, height)
    local max_line_width = 0
    for _, line in ipairs(lines) do
        local w = vim.fn.strdisplaywidth(line)
        if w > max_line_width then
            max_line_width = w
        end
    end

    local top_pad = math.max(math.floor((height - #lines) / 2), 0)
    local left_pad = math.max(math.floor((width - max_line_width) / 2), 0)
    local pad_str = string.rep(" ", left_pad)

    first_item_row = top_pad + 1
    first_item_col = left_pad

    local centered = {}
    for _ = 1, top_pad do
        table.insert(centered, "")
    end
    for _, line in ipairs(lines) do
        table.insert(centered, pad_str .. line)
    end

    return centered
end

local function set_centered_content(lines, width, height)
    current_lines = lines
    local centered = center_lines(lines, width, height)
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, centered)
    vim.bo[buffer].modifiable = false

    -- 창이 열려 있으면 첫 번째 항목("[e] ...") 줄로 커서 자동 배치
    vim.schedule(function()
        if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
            return
        end
        for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
            if vim.api.nvim_win_is_valid(win) then
                pcall(vim.api.nvim_win_set_cursor, win, { first_item_row, first_item_col })
            end
        end
    end)
end

local function bind_keymaps()
    local opts = { buffer = buffer, silent = true, nowait = true }

    -- 1) 단축키(e, f, g, q, t, p, w) 직접 입력 시 동작
    for key, fn in pairs(actions) do
        vim.keymap.set("n", key, fn, opts)
    end

    -- 2) Enter(<CR>) 입력 시 현재 커서가 위치한 줄의 [key]를 파싱하여 동작 실행
    vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local key = line:match("%[(%w)%]")
        if key and actions[key] then
            actions[key]()
        end
    end, opts)
end

function M.setup()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].buftype = "nofile"
    bind_keymaps()

    -- 기존 레이아웃 전환용 resize와는 별개로,
    -- panel_project의 window가 현재 열려 있을 때만 동작하는 전용 resize 코드
    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
                return
            end
            local wins = vim.fn.win_findbuf(buffer)
            if #wins == 0 then
                return
            end
            local win = wins[1]
            if not vim.api.nvim_win_is_valid(win) or #current_lines == 0 then
                return
            end

            vim.schedule(function()
                if not vim.api.nvim_win_is_valid(win) then
                    return
                end
                local width = vim.api.nvim_win_get_width(win)
                local height = vim.api.nvim_win_get_height(win)
                set_centered_content(current_lines, width, height)
            end)
        end,
    })
end

function M.get_buf()
    return buffer
end

function M.get_content()
    return panel.content
end

-- current_right_mode: 현재 우측에 띄워진 패널 ("vim" 또는 "workspace")
-- 토글('t') 시 바뀌게 될 대상 버퍼 이름을 단축키와 함께 표시
function M.get_half_content(current_right_mode)
    local toggle_line
    if current_right_mode == "vim" then
        toggle_line = "[t] Open Workspaces"
    else
        toggle_line = "[t] Vim/Nvim Process"
    end
    return vim.list_extend(vim.deepcopy(panel.content), {
        toggle_line,
    })
end

function M.get_quarter_content()
    return vim.list_extend(vim.deepcopy(panel.content), {
        "[p] Vim/Nvim Process",
        "[w] Open Workspaces",
    })
end

function M.get_panel(row, col, width, height)
    set_centered_content(M.get_content(), width, height)
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
    }
    return { win_config, buffer }
end

function M.get_half_panel(row, col, width, height, current_right_mode)
    set_centered_content(M.get_half_content(current_right_mode), width, height)
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
    }
    return { win_config, buffer }
end

function M.get_quarter_panel(row, col, width, height)
    set_centered_content(M.get_quarter_content(), width, height)
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
    }
    return { win_config, buffer }
end

return M
