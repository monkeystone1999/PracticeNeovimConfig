return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "" },
            topdelete = { text = "" },
            changedelete = { text = "▎" },
            untracked = { text = "┆" },
        },
        signs_staged = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "" },
            topdelete = { text = "" },
            changedelete = { text = "▎" },
        },
        current_line_blame = false, -- <leader>tb 로 필요할 때 즉시 토글
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol",
            delay = 300,
        },
        preview_config = {
            border = "rounded",
            style = "minimal",
        },
        on_attach = function(buffer)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, desc)
                vim.keymap.set(mode, l, r, { buffer = buffer, silent = true, desc = desc })
            end

            -- Hunk 이동 (]c / [c 는 text_obj.lua 의 클래스/구조체 이동과 겹치지 않도록 ]h / [h 사용)
            map("n", "]h", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    gs.nav_hunk("next")
                end
            end, "다음 Git 변경 블록(Hunk)")

            map("n", "[h", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    gs.nav_hunk("prev")
                end
            end, "이전 Git 변경 블록(Hunk)")

            map("n", "]H", function()
                gs.nav_hunk("last")
            end, "마지막 Git Hunk")

            map("n", "[H", function()
                gs.nav_hunk("first")
            end, "첫 번째 Git Hunk")

            -- Hunk 스테이징 / 되돌리기 / 미리보기 (<leader>gh*)
            map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Git: Hunk 스테이징")
            map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Git: Hunk 되돌리기(Reset)")
            map("n", "<leader>ghS", gs.stage_buffer, "Git: 현재 파일 전체 스테이징")
            map("n", "<leader>ghu", gs.undo_stage_hunk, "Git: Hunk 스테이징 취소")
            map("n", "<leader>ghR", gs.reset_buffer, "Git: 현재 파일 변경사항 전체 초기화")
            map("n", "<leader>ghp", gs.preview_hunk_inline, "Git: Hunk 변경사항 인라인 미리보기")
            map("n", "<leader>ghb", function()
                gs.blame_line({ full = true })
            end, "Git: 현재 줄 전체 Blame 팝업")
            map("n", "<leader>ghd", gs.diffthis, "Git: 현재 파일 Diff 보기")
            map("n", "<leader>ghD", function()
                gs.diffthis("~")
            end, "Git: 직전 커밋(~)과 Diff 보기")

            -- 토글 (<leader>t* 계열 통일)
            map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle Git Current Line Blame")
            map("n", "<leader>tw", gs.toggle_word_diff, "Toggle Git Word Diff")

            -- Hunk 텍스트 오브젝트 (예: vih 로 변경 블록 선택, dih 로 삭제)
            map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git Hunk 선택")
        end,
    },
}
