return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    main = "nvim-treesitter.configs",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "lua", "vim", "vimdoc", "javascript", "typescript", "python", "html", "css", "json", "makdown"
            },
            auto_install = true,
            -- highlighter
            highlight = {
                enalbe = true,
                additional_vim_regex_highlighting = false,
                disable = function(lang, buf)
                    local ft = vim.bo[buf].filetype
                    return ft == "netrw" or vim.bo[buf].buftype ~= ""
                end,
            },
            indent = {
                enalbe = true,
            },
        })
    end,
}
