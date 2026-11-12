return {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "LazyGit" },
    keys = {
        { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit 열기" },
    },
    config = function()
        -- 1. 창 크기 비율 조절 (0.0 ~ 1.0)
        -- 기본값은 0.9 (화면의 90%)이며, 가로/세로가 에디터 크기에 비례하여 줄어듭니다.
        -- 예: 0.7로 설정하면 화면의 70% 크기로 작게 표시됩니다.
        vim.g.lazygit_floating_window_scaling_factor = 0.8

        -- 2. 배경 투명도 조절 (0 ~ 100)
        -- 기본값은 0 (완전 불투명)입니다.
        -- 숫자가 커질수록 투명해지며, 보통 10~20 사이가 코드 가독성을 해치지 않고 적당합니다.
        vim.g.lazygit_floating_window_winblend = 15

        -- (선택) 테두리 스타일 변경 ('single', 'double', 'rounded', 'solid' 등)
        vim.g.lazygit_floating_window_border_chars = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }
    end
}
