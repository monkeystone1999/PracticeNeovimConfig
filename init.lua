if vim.g.vscode then
    -- VSCode extension
else
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
    vim.opt.wildoptions = "pum"


    -- vim.opt.winbar = "%= %f %m %="

    vim.opt.showtabline = 0
    vim.keymap.set("n", "q:", "<Nop>")
    if vim.g.neovide then
        -- 폰트 설정 (설치된 폰트명과 크기 지정)
        -- vim.o.guifont = "JetBrainsMono Nerd Font:h14,D2Coding:h11"
        vim.opt.guifont = { "Cascadia Code", ":h14" }



        -- vim.opt.guifont = { "JetBrainsMono Nerd Font", "D2Coding", ":h11" }

        -- 창 투명도 및 블러 (0.0 ~ 1.0)
        vim.g.neovide_transparency = 0.95
        vim.g.neovide_scroll_animation_length = 0.3

        -- 커서 애니메이션 설정
        vim.g.neovide_cursor_animation_length = 0.13 -- 이동 속도 (0이면 애니메이션 비활성화)
        vim.g.neovide_cursor_trail_size = 0.8        -- 잔상 길이 (0.0 ~ 1.0)
        vim.g.neovide_cursor_vfx_mode =
        "railgun"                                    -- 효과: "railgun", "torpedo", "pixiedust", "sonicboom", "ripple", "wireframe"

        -- Windows 창 외관 및 동작
        vim.g.neovide_corner_preference = "round"   -- 모서리 둥글기 ("round", "square")
        vim.g.neovide_hide_mouse_when_typing = true -- 타이핑 시 마우스 커서 숨김
        vim.g.neovide_remember_window_size = true   -- 이전 창 크기 기억
        vim.g.neovide_confirm_quit = true           -- 종료 확인 프롬프트

        -- 입력 및 클립보드 (Ctrl+Shift+V / Ctrl+Shift+C 붙여넣기/복사)
        vim.keymap.set('n', '<C-S-v>', '"+P')
        vim.keymap.set('i', '<C-S-v>', '<C-r>+')
        vim.keymap.set('v', '<C-S-c>', '"+y')
    end
end
