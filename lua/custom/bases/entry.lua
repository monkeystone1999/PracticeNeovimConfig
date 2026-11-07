local M = {}

local function detect_entry_type()
    local argc = vim.fn.argc()
    if argc == 0 then
        return "empty", nil
    end
    local first_arg = vim.fn.argv(0) ---@type string
    local abs_path = M.normalize(first_arg)
    if vim.fn.isdirectory(first_arg) == 1 then
        return "dir", (abs_path)
    else
        return "file", (abs_path)
    end
end

local abs_path
local state


function M.setup()
    state, abs_path = detect_entry_type()
end

function M.get_state()
    return state
end

function M.get_abs_path()
    return abs_path
end

function M.normalize(path)
    return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

return M
