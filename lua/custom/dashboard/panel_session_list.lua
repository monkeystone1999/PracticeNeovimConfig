local M = {}

local session_list = require("custom.dashboard.find_session_list")
local buffer = nil
local panel = {
    title = "Project",
    content = {

    },
}

function M.setup()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].buftype = 'nofile'
end

function M.get_content()
    local session_list = session_list.get_info()
    if #session_list == 0 then
        panel.content = "현재 Workspace 가 없습니다"
    else
        panel.content = session_list
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
