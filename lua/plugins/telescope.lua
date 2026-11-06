return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",               -- 또는 branch = '0.1.x'
    dependencies = {
        "nvim-lua/plenary.nvim", -- 필수 의존성 플러그인
    },
    config = function()
        local builtin = require("telescope.builtin")

        -- 💡 Telescope 단축키 설정 (<leader>f 계열)
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files (프로젝트 파일 검색)" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep (프로젝트 내 텍스트 검색)" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers (열린 버퍼 목록)" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help (Neovim 도움말 검색)" })
        vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files (최근 연 파일)" })

        -- UI 및 동작 기본 설정
        require("telescope").setup({
            defaults = {
                path_display = { "smart" },
                mappings = {
                    i = {
                        ["<C-j>"] = "move_selection_next",     -- Ctrl+j 로 아래 이동
                        ["<C-k>"] = "move_selection_previous", -- Ctrl+k 로 위 이동
                        ["<C-c>"] = "close",                   -- Ctrl+c 로 창 닫기
                    },
                },
            },
        })
    end,
}
