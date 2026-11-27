return {
    -- 1. 워크스페이스 진단(에러/경고), LSP 참조, 심볼 트리 전용 패널
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            focus = true,
        },
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Trouble: 워크스페이스 전체 에러/경고 목록",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Trouble: 현재 파일 에러/경고 목록",
            },
            {
                "<leader>xs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Trouble: 현재 파일 심볼(함수/클래스) 트리",
            },
            {
                "<leader>xr",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "Trouble: LSP 정의/참조/구현 목록",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Trouble: Location List 토글",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Trouble: Quickfix 목록 토글",
            },
            {
                "[q",
                function()
                    if require("trouble").is_open() then
                        require("trouble").prev({ skip_groups = true, jump = true })
                    else
                        local ok, err = pcall(vim.cmd.cprev)
                        if not ok then
                            vim.notify(err, vim.log.levels.ERROR)
                        end
                    end
                end,
                desc = "이전 Trouble / Quickfix 항목",
            },
            {
                "]q",
                function()
                    if require("trouble").is_open() then
                        require("trouble").next({ skip_groups = true, jump = true })
                    else
                        local ok, err = pcall(vim.cmd.cnext)
                        if not ok then
                            vim.notify(err, vim.log.levels.ERROR)
                        end
                    end
                end,
                desc = "다음 Trouble / Quickfix 항목",
            },
        },
    },

    -- 2. 코드 내 TODO / FIXME / HACK / NOTE 주석 하이라이트 및 검색
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        opts = {},
        keys = {
            {
                "]t",
                function()
                    require("todo-comments").jump_next()
                end,
                desc = "다음 TODO 주석으로 이동",
            },
            {
                "[t",
                function()
                    require("todo-comments").jump_prev()
                end,
                desc = "이전 TODO 주석으로 이동",
            },
            {
                "<leader>xt",
                "<cmd>Trouble todo toggle<cr>",
                desc = "Trouble: 프로젝트 전체 TODO 목록",
            },
            {
                "<leader>xT",
                "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
                desc = "Trouble: TODO/FIX/FIXME 핵심 항목만 보기",
            },
            {
                "<leader>ft",
                "<cmd>TodoTelescope<cr>",
                desc = "Find TODOs (프로젝트 TODO 주석 검색)",
            },
        },
    },
}
