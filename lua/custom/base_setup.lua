local M = {}

function M.all_setup()
    local files = vim.api.nvim_get_runtime_file("lua/custom/bases/*.lua", true)
    for _, filepath in ipairs(files) do
        local module_path = filepath:match(".*/lua/(custom/bases/.*)%.lua$")
        if module_path then
            local module_name = module_path:gsub("/", ".")
            local module = require(module_name)
            if type(module) == "table" and type(module.setup) == "function" then
                module.setup()
            end
        end
    end
end

function M.setup()
    require("custom.bases.entry").setup()
    require("custom.bases.lualine").setup()
    require("custom.bases.winbar").setup()
    require("custom.bases.workspace").setup()
end

return M
