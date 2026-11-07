local M = {}
local api = require("custom.dashboard.find_vim_process")

local panel = {
    title = "Vim/Nvim Processes",
    content = {},

}
local buffer




function M.setup()
    api.setup()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].buftype = "nofile"
    --[[     vim.bo[buffer].modified = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, M.get_content())
    vim.bo[buffer].modified = false ]]
end

function M.get_content()
    local procs = api.get_info()
    if #procs == 0 then
        panel.content = "현재 감지된 다른 Vim/Nvim 프로세스가 없습니다 "
    else
        panel.content = procs
    end
    return panel
end

function M.get_panel(row, col, width, height)
    vim.bo[buffer].modified = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, M.get_content())
    vim.bo[buffer].modified = false
    local win_config = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = panel.title,
        title_pos = "center"
    }
    return { win_config, buffer }
end

return M
