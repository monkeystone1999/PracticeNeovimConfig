-- Workspace 별 buffer 목록을 winbar 에 표시
local ws = require("workspace")

local M = {}

local expr = "%!v:lua.require('workspace.winbar').render()"
local links = { WsBar = "WinBar", WsBarSel = "TabLineSel", WsBarTitle = "Title" }

local function esc(s) return (s:gsub("%%", "%%%%")) end

local function eligible(win)
    return vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

function M.render()
    local win = vim.g.statusline_winid
    local tab = vim.api.nvim_win_get_tabpage(win)
    local cur = vim.api.nvim_win_get_buf(win)

    local out = { "%#WsBarTitle# " .. esc(ws.name(tab)) .. " %#WsBar#%<" }
    for i, buf in ipairs(ws.buffers(tab)) do
        local tail = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        out[#out + 1] = ("%s %d:%s%s "):format(
            buf == cur and "%#WsBarSel#" or "%#WsBar#",
            i,
            esc(tail),
            vim.bo[buf].modified and " +" or ""
        )
    end
    out[#out + 1] = "%#WsBar#"
    return table.concat(out)
end

function M.setup()
    local function highlights()
        for name, link in pairs(links) do
            vim.api.nvim_set_hl(0, name, { link = link, default = true })
        end
    end
    highlights()

    local group = vim.api.nvim_create_augroup("workspace_winbar", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
    vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter", "TabEnter" }, {
        group = group,
        callback = function()
            local win = vim.api.nvim_get_current_win()
            vim.wo[win].winbar = eligible(win) and expr or ""
        end,
    })
end

return M
