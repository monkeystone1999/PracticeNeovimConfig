return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    opts = {
        ensure_installed = {
            "lua", "vim", "vimdoc", "javascript", "typescript", "python", "html", "css", "json", "markdown", "c",
            "cpp",
        },
        indent = { enable = true },
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        auto_install = true,
    },
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end,
}
