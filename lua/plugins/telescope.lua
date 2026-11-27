return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim", -- 필수 의존성 플러그인
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
        },
    },
    opts = {
        defaults = {
            path_display = { "smart" },
            mappings = {
                i = {
                    ["<C-j>"] = "move_selection_next",     -- Ctrl+j 로 아래 이동
                    ["<C-k>"] = "move_selection_previous", -- Ctrl+k 로 위 이동
                    ["<C-c>"] = "close",                   -- Ctrl+c 로 창 닫기
                },
                n = {
                    ["q"] = "close",                       -- 노멀 모드에서 q 로 창 닫기
                },
            },
        },
    },
    config = function(_, opts)
        local telescope = require("telescope")
        local builtin = require("telescope.builtin")

        -- 💡 Telescope 단축키 설정 (<leader>f 계열)
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files (프로젝트 파일 검색)" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep (프로젝트 내 텍스트 검색)" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers (열린 버퍼 목록)" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help (Neovim 도움말 검색)" })
        vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files (최근 연 파일)" })
        vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Find commands (명령어 팔레트 검색)" })
        vim.keymap.set("n", "<leader>:", builtin.commands, { desc = "Command Palette (명령어 팔레트)" })

        -- UI 및 동작 기본 설정 (ui-select 등 외부 확장의 opts 병합 지원)
        telescope.setup(opts)

        -- C 네이티브 퍼지 정렬 확장 로드 (미빌드 환경에서도 에러가 나지 않도록 pcall 보호)
        pcall(telescope.load_extension, "fzf")
    end,
}
