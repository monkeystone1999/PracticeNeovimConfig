return {
    "danymat/neogen",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    cmd = "Neogen",
    keys = {
        {
            "<leader>nf",
            function()
                require("neogen").generate()
            end,
            desc = "Neogen: 현재 위치(함수/클래스) Doxygen 주석 생성",
        },
        {
            "<leader>nc",
            function()
                require("neogen").generate({ type = "class" })
            end,
            desc = "Neogen: 클래스/구조체 Doxygen 주석 생성",
        },
        {
            "<leader>nF",
            function()
                require("neogen").generate({ type = "file" })
            end,
            desc = "Neogen: 파일 상단 Doxygen 주석 생성",
        },
    },
    opts = {
        enabled = true,
        -- 현재 프로젝트에는 LuaSnip이 설치되어 있지 않으므로,
        -- Neovim 0.10+ 기본 내장 스니펫 엔진("nvim", vim.snippet)을 사용해야 에러 없이 동작합니다.
        snippet_engine = "nvim",
        languages = {
            c = {
                template = {
                    annotation_convention = "doxygen",
                },
            },
            cpp = {
                template = {
                    annotation_convention = "doxygen",
                },
            },
        },
    },
}
