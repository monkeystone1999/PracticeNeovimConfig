local M = {}

local explorer_win = nil -- 💡 탐색기 창 ID를 전역으로 추적하여 중복 생성 완벽 차단

-- --------------------------------------------------------------------------
-- 💡 전역/공유 함수: 왼쪽 고정 30칸 커스텀 탐색기 창 열기
-- --------------------------------------------------------------------------
local function open_fixed_explorer()
    -- 이미 열려있고 유효한 창이라면 포커스만 이동시키고 종료
    if explorer_win and vim.api.nvim_win_is_valid(explorer_win) then
        vim.api.nvim_set_current_win(explorer_win)
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)

    vim.cmd("topleft vsplit")
    vim.cmd("vertical resize 30")

    explorer_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(explorer_win, buf)

    -- 💡 강제로 최좌측 고정: 다른 창이 있어도 무조건 가장 왼쪽으로 밀어냅니다.
    vim.cmd("wincmd H")

    local current_dir = vim.fn.getcwd(0, 0)
    vim.cmd("edit " .. vim.fn.fnameescape(current_dir))
end

local function set_buffer_name()
    local tcd = vim.fn.getcwd()
    vim.bo.modifiable = true
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { tcd })
    vim.bo.modifiable = false
    vim.bo.modified = false
end

local function set_winbar_name()
    return vim.fn.getcwd(0, 0)
end


-- --------------------------------------------------------------------------
-- 🚀 메인 셋업 함수
-- --------------------------------------------------------------------------
function M.setup()
    vim.g.netrw_banner = 0
    vim.g.netrw_liststyle = 3
    -- 💡 파일 열기 정책 변경 (4 = 이전 메인 편집 창에 파일 열기)
    vim.g.netrw_browse_split = 4
    vim.opt.splitright = true

    vim.keymap.set('n', '<leader>e', open_fixed_explorer, { desc = "Netrw 탐색기 좌측 열기" })

    vim.api.nvim_create_autocmd('VimEnter', {
        group = vim.api.nvim_create_augroup("LayoutControl", { clear = true }),
        pattern = '*',
        callback = function()
            local arg = vim.fn.argv(0)
            if not arg or arg == "" then return end

            local path = vim.fn.fnamemodify(arg, ":p")
            pcall(vim.cmd, "tcd " .. vim.fn.fnameescape(path))

            if vim.fn.isdirectory(path) == 1 then
                local empty_buf = vim.api.nvim_create_buf(true, false)
                vim.api.nvim_win_set_buf(0, empty_buf)
                open_fixed_explorer()
                vim.cmd("wincmd l")
            end
        end
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("NetrwCustomKeymaps", { clear = true }),
        pattern = "netrw",
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            local opts = { remap = false, silent = true, buffer = bufnr }
            vim.opt_local.winbar = set_winbar_name();

            -- ① Enter: 폴더면 tcd 변경 + 트리 펼치기 / 파일이면 우측 창에 열기
            vim.keymap.set("n", "<CR>", function()
                local current_line = vim.fn.getline(".")
                if current_line == "" or current_line:match("^%.%./") then
                    vim.cmd("normal! -")
                    return
                end

                local target_path = vim.fn["netrw#Call"]("NetrwGetWord")

                if vim.fn.isdirectory(target_path) == 1 then
                    vim.cmd("tcd " .. vim.fn.fnameescape(target_path))
                    print("📁 Tab CWD 변경 완료: " .. target_path)
                end

                -- 💡 핵심: edit 대신 netrw 고유 브라우징 함수를 직접 호출하여 트리 구조 유지
                vim.cmd([[call netrw#LocalBrowseCheck(netrw#Call("NetrwBrowseChqDir"))]])
            end, opts)

            -- ② l (오른쪽): 트리 펼치거나 파일 열기 (위의 <CR>과 완전히 동일한 동작)
            vim.keymap.set("n", "l", function()
                local current_line = vim.fn.getline(".")
                if current_line == "" or current_line:match("^%.%./") then return end
                vim.cmd([[call netrw#LocalBrowseCheck(netrw#Call("NetrwBrowseChqDir"))]])
            end, opts)

            -- ③ h (왼쪽): 트리 접기 또는 상위 디렉토리로 이동 (netrw 내장 '-' 활용)
            vim.keymap.set("n", "h", function()
                vim.cmd("normal! -")
            end, opts)

            -- ④ <ESC>: Explorer 창 닫기
            vim.keymap.set("n", "<ESC>", function()
                vim.cmd("quit")
            end, opts)
        end,
    })
end

return M
