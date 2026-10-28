-- Floating window 유틸 (상태 없음). 크기는 전부 vim.o.columns / vim.o.lines 에서 계산.
local M = { ratio = 0.8 }

local BORDER = 2 -- border 상하/좌우 두께 합

local function layout(buf, opts)
    local cols, rows = vim.o.columns, vim.o.lines - vim.o.cmdheight
    local w = math.floor((cols - BORDER) * M.ratio)
    local h = math.floor((rows - BORDER) * M.ratio)

    if opts.fit then -- 내용 크기에 맞추되 ratio 를 넘지 않는다
        local lines, widest = vim.api.nvim_buf_get_lines(buf, 0, -1, false), 0
        for _, l in ipairs(lines) do
            widest = math.max(widest, vim.fn.strdisplaywidth(l))
        end
        w, h = math.min(w, widest), math.min(h, #lines)
    end

    w, h = math.max(w, 1), math.max(h, 1)
    return {
        relative = "editor",
        width = w,
        height = h,
        col = math.floor((cols - w - BORDER) / 2),
        row = math.floor((rows - h - BORDER) / 2),
    }
end

--- opts: title, fit(bool), cursorline(bool)
function M.float(buf, opts)
    opts = opts or {}
    local win = vim.api.nvim_open_win(buf, true, vim.tbl_extend("force", layout(buf, opts), {
        style = "minimal",
        border = "rounded",
        title = opts.title,
        title_pos = opts.title and "center" or nil,
    }))
    vim.wo[win].winbar = ""
    vim.wo[win].cursorline = opts.cursorline == true

    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if not vim.api.nvim_win_is_valid(win) then return true end -- true: autocmd 제거
            vim.api.nvim_win_set_config(win, layout(buf, opts))
        end,
    })
    return win
end

return M
