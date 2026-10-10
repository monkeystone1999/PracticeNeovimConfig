-- ==========================================================================
-- 1. 탭 및 들여쓰기 설정 (Tabs & Indentation) - 질문하신 핵심 설정입니다.
-- ==========================================================================
vim.opt.tabstop = 4        -- Tab 키를 눌렀을 때 화면에 표시되는 공백 개수
vim.opt.shiftwidth = 4     -- >>, << 명령이나 자동 들여쓰기 시 이동할 공백 개수
vim.opt.expandtab = true   -- Tab 키를 입력하면 공백(Space) 문자로 자동 전환 (소프트 탭)
vim.opt.smarttab = true    -- 줄 시작 부분에서 Tab 입력 시 shiftwidth 기준 적용
vim.opt.autoindent = true  -- 새 줄을 시작할 때 이전 줄의 들여쓰기를 그대로 유지
vim.opt.smartindent = true -- C언어 스타일 등의 구문에 맞춰 자동으로 들여쓰기 깊이 조절

-- ==========================================================================
-- 2. 화면 및 UI 표시 설정 (UI & Display)
-- ==========================================================================
vim.opt.number = true         -- 좌측에 절대 행(라인) 번호 표시
vim.opt.relativenumber = true -- 현재 커서 기준으로 위아래 상대적 행 번호 표시 (점프 이동 시 필수)
vim.opt.cursorline = true     -- 커서가 위치한 줄에 하이라이트(밑줄 또는 배경색) 표시
vim.opt.termguicolors = true  -- 24비트 RGB 트루컬러 지원 (최신 테마 적용을 위한 필수 설정)
vim.opt.signcolumn = "yes"    -- 좌측에 Git 상태나 에러(LSP) 아이콘이 들어갈 공간을 항상 확보
vim.opt.scrolloff = 8         -- 커서 위아래로 최소 8줄의 여유 공간을 유지하며 스크롤 (화면 끝 방지)
vim.opt.sidescrolloff = 8     -- 가로 스크롤 시 커서 좌우로 최소 8칸의 여유 공간 유지
vim.opt.wrap = false          -- 긴 문장이 화면을 넘어가도 다음 줄로 줄바꿈하지 않음 (가로로 계속 유지)
vim.opt.cmdheight = 0         -- 하단 명령줄 창의 높이 (0으로 설정 시 평소엔 숨김 가능)
vim.opt.showmode = false      -- 하단에 -- INSERT -- 같은 모드 표시를 끔 (어차피 상태바 플러그인이 표시하므로)

-- ==========================================================================
-- 3. 검색 및 매칭 설정 (Search & Matching)
-- ==========================================================================
vim.opt.hlsearch = true   -- 검색 매칭된 단어에 하이라이트 유지
vim.opt.incsearch = true  -- 검색어를 타이핑하는 동안 실시간으로 매칭 결과로 이동
vim.opt.ignorecase = true -- 검색 시 대소문자를 구분하지 않음
vim.opt.smartcase = true  -- 대문자가 하나라도 포함되면 대소문자를 엄격하게 구분해 검색
vim.opt.showmatch = true  -- 괄호를 닫을 때( }, ], ) ) 매칭되는 열린 괄호를 깜빡여서 표시

-- ==========================================================================
-- 4. 시스템 및 성능 설정 (System & Performance)
-- ==========================================================================
vim.opt.clipboard = "unnamedplus" -- 시스템 클립보드와 Neovim 클립보드 연동 (외부에서 복사 후 nvim에서 붙여넣기 가능)
vim.opt.mouse = "a"               -- 마우스 클릭, 드래그, 휠 스크롤 모두 허용
vim.opt.updatetime = 250          -- Neovim이 변경사항을 디스크에 기록하거나 이벤트를 트리거하는 대기 시간 (기본 4000ms는 너무 느림)
vim.opt.timeoutlen = 300          -- 단축키 조합(예: `gg`) 입력 시 다음 키를 기다리는 제한 시간 (밀리초)
vim.opt.swapfile = false          -- 스왑 파일(.swp) 생성을 비활성화 (갑작스러운 종료 시 복구 파일 안 만듦)
vim.opt.backup = false            -- 백업 파일을 생성하지 않음
vim.opt.undofile = true           -- Neovim을 껐다 켜도 이전의 실행 취소(Undo) 기록을 유지 (기록은 별도 캐시에 저장됨)
vim.opt.fileencoding = "utf-8"    -- 파일 저장 시 기본 인코딩 지정

-- ==========================================================================
-- 5. 창 분할 및 자동완성 메뉴 (Splits & Completion UI)
-- ==========================================================================
vim.opt.splitright = true -- `:vsplit` 창 분할 시 새로운 창을 오른쪽에 열기 (기본값은 왼쪽)
vim.opt.splitbelow = true -- `:split` 창 분할 시 새로운 창을 아래쪽에 열기 (기본값은 위쪽)
vim.opt.pumheight = 10    -- 코드 자동완성 팝업 메뉴의 최대 높이를 10줄로 제한
vim.opt.wildmenu = true   -- 커맨드라인 자동완성 메뉴 활성화

vim.g.mapleader = " "
vim.g.maplocalleader = " " -- 로컬 리더도 스페이스바로 설정할 때 (선택사항)
vim.opt.laststatus = 3


-- vim.opt.winbar = "%= %f %m %="

vim.opt.showtabline = 0

if vim.g.vscode then
    -- VSCode extension
else
    vim.keymap.set("n", ":", "q:A", { noremap = true, silent = true })
    vim.api.nvim_create_autocmd("CmdwinEnter", {
        pattern = ":",
        callback = function(args)
            vim.cmd("resize 10")
            vim.keymap.set("n", "<Esc", ":q<CR>", { buffer = true, silent = true })
        end
    })
    require("plugins.explorer").setup()
    -- ordinary Nvim
    local buf
    --[[
vim.keymap.set('n', '<F9>', function()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = 100,
        height = 100,
        row = 50,
        col = 50,
        style = "minimal",
        border = "rounded"
    })
    vim.keymap.set('n', '<ESC>', function()
        vim.api.nvim_buf_delete(buf, {
            unload = true
        })
    end, {
        buffer = buf
    })
end)



vim.api.nvim_create_autocmd('BufWrite', {
    pattern = '*',
    callback = function(args)
        vim.schedule(function()
            local text = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local buff = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_open_win(buff, true, {
                relative = "editor",
                width = 100,
                height = 50,
                row = 50,
                col = 50,
                style = "minimal",
                border = "rounded"
            })
            vim.api.nvim_buf_set_lines(buff, 0, -1, true, text)
            vim.keymap.set('n', '<ESC>', function()
                vim.api.nvim_buf_delete(buff, {
                    unload = true
                })
            end, {
                buffer = buff
            }
            )
        end)
    end
})
 ]]
end
