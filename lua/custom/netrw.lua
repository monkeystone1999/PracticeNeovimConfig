local M = {}

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1

local function toggle_netrw()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "netrw" then
            vim.api.nvim_win_close(win, true)
            return
        end
    end
    vim.cmd("topleft Lexplore")
end

function M.setup()
    vim.keymap.set("n", "<leader>e", toggle_netrw, { desc = "Toggle Left Netrw" })
    -- netrw 버퍼가 열릴 때 전용 단축키 적용
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "netrw",
        callback = function()
            local function map(lhs, rhs, desc)
                -- remap = true 로 설정해야 netrw의 내부 기본 키 동작(-, gh, % 등)이 연결됩니다.
                vim.keymap.set("n", lhs, rhs, { remap = true, buffer = true, silent = true, desc = desc })
            end

            -- 1. 디렉터리 이동 (h / l)
            map("h", "-", "Go to parent directory") -- h: 상위 폴더로 이동 (기본 -)
            map("l", "<CR>", "Open file or directory") -- l: 파일 열기 / 폴더 진입 (기본 Enter)

            -- 2. 파일 및 폴더 관리 (a / r / d)
            map("a", "%", "Create new file")   -- a: 새 파일/폴더 생성 (기본 %)
            map("r", "R", "Rename file/directory") -- r: 이름 변경 (기본 R)
            map("d", "D", "Delete file/directory") -- d: 파일/폴더 삭제 (기본 D)

            -- 3. 유용한 기능 (숨김 파일, 분할 열기)
            map(".", "gh", "Toggle hidden files") -- .: 숨김 파일(.dotfiles) 토글 (기본 gh)
            map("v", "v", "Open in vertical split") -- v: 세로 분할로 파일 열기
            map("s", "o", "Open in horizontal split") -- s: 가로 분할로 파일 열기 (기본 o)

            -- 4. 닫기 단축키 (q / <Esc>)
            vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
            vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = true, silent = true })
        end,
    })
end

return M
