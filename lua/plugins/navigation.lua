return {
    -- 1. 화면 내 임의 위치 2~3타 순간이동 및 Treesitter 구문 점프/선택
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {},
        keys = {
            {
                "s",
                mode = { "n", "x", "o" },
                function()
                    require("flash").jump()
                end,
                desc = "Flash: 화면 내 빠른 점프",
            },
            {
                "S",
                mode = { "n", "x", "o" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash: Treesitter 구문 노드 선택",
            },
            {
                "r",
                mode = "o",
                function()
                    require("flash").remote()
                end,
                desc = "Flash: 원격(Remote) 조작 후 원래 커서 복귀",
            },
            {
                "R",
                mode = { "o", "x" },
                function()
                    require("flash").treesitter_search()
                end,
                desc = "Flash: 텍스트 검색 + Treesitter 범위 선택",
            },
            {
                "<c-s>",
                mode = { "c" },
                function()
                    require("flash").toggle()
                end,
                desc = "Flash: 일반 검색(/) 중 라벨 점프 토글",
            },
        },
    },

    -- 2. 자주 오가는 핵심 파일(.h / .cpp 등) 핀 고정 및 즉시 전환 (Harpoon 2)
    -- (<leader>a 는 text_obj.lua 의 매개변수 스왑이므로 충돌 없는 <leader>h* 및 <leader>1~4 사용)
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        opts = {
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                -- 자체 탭 워크스페이스(tcd) 경로별로 핀 목록이 독립 관리되도록 연동
                key = function()
                    return vim.fn.getcwd(0)
                end,
            },
        },
        config = function(_, opts)
            require("harpoon"):setup(opts)
        end,
        keys = {
            {
                "<leader>ha",
                function()
                    require("harpoon"):list():add()
                    vim.notify("현재 파일을 Harpoon에 고정했습니다.", vim.log.levels.INFO, { title = "Harpoon" })
                end,
                desc = "Harpoon: 현재 파일 추가",
            },
            {
                "<leader>hh",
                function()
                    local harpoon = require("harpoon")
                    harpoon.ui:toggle_quick_menu(harpoon:list(), {
                        border = "rounded",
                        title_pos = "center",
                    })
                end,
                desc = "Harpoon: 고정 파일 목록 토글",
            },
            {
                "<leader>1",
                function()
                    require("harpoon"):list():select(1)
                end,
                desc = "Harpoon: 1번 파일로 이동",
            },
            {
                "<leader>2",
                function()
                    require("harpoon"):list():select(2)
                end,
                desc = "Harpoon: 2번 파일로 이동",
            },
            {
                "<leader>3",
                function()
                    require("harpoon"):list():select(3)
                end,
                desc = "Harpoon: 3번 파일로 이동",
            },
            {
                "<leader>4",
                function()
                    require("harpoon"):list():select(4)
                end,
                desc = "Harpoon: 4번 파일로 이동",
            },
            {
                "<leader>hp",
                function()
                    require("harpoon"):list():prev()
                end,
                desc = "Harpoon: 이전 고정 파일",
            },
            {
                "<leader>hn",
                function()
                    require("harpoon"):list():next()
                end,
                desc = "Harpoon: 다음 고정 파일",
            },
        },
    },
}
