local M = {}

function M.detect_entry_type()
    local argc = vim.fn.argc()
    if argc == 0 then
        return "empty", nil
    end
    local first_arg = vim.fn.argv(0) -- [[@as string]]
    local abs_path = vim.fn.fnamemodify(first_arg, ":p")
    if vim.fn.isdirectory(first_arg) == 1 then
        return "dir", abs_path:gsub("/$", "")
    else
        return "file", abs_path
    end
end

return M
