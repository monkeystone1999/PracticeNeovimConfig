local M = {}

local buffer = nil

local panel = {
    title = "Project",
    content = {
        "[e] File Explorer (Oil)",
        "[f] Find Files",
        "[g] Live Grep",
        "[f] Find Files",
        "[q] Quick Dashboard",
    },
}

function M.setup()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].buftype = 'nofile'
end

function M.get_content()
    return { panel.content }
end

function M.get_half_content()
    return { panel.content, "[p] Vim/Nvim Process", "[s] Open Workspaces" }
end

function M.get_quarter_content()

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

function M.get_half_panel(row, col, width, height)

end

function M.get_quater_panel(row, col, width, height)

end

return M
