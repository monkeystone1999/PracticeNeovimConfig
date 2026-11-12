return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        ts.setup()

        -- 필요한 파서 자동 설치 (이미 설치되어 있으면 무시됨)
        ts.install({
            "lua",
            "vim",
            "vimdoc",
            "javascript",
            "typescript",
            "python",
            "html",
            "css",
            "json",
            "markdown",
            "c",
            "cpp",
            "cmake",
        })

        -- 파일 열릴 때 Treesitter 하이라이팅 및 들여쓰기 활성화
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
            callback = function(ev)
                if pcall(vim.treesitter.start, ev.buf) then
                    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}
