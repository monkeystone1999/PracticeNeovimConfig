local workspaces = {}

local function add_workspace(name, locate)
    local items = {}
end

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        pattern = '*',
        callback = function(args)
            local arg = vim.vim.fn.argv(0)
        end
    })
end

return M
