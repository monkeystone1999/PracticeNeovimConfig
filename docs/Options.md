# `vim.opt` 인터페이스

## 값 대입
- `vim.opt.옵션명 = 값` 형태로 대입한다.
- 전역 변수는 `vim.g.*`(예: `mapleader`, 플러그인/Neovide 전역 옵션), 버퍼 로컬 옵션은 `vim.bo[buf].*`, 윈도우 로컬 옵션은 `vim.wo[win].*`를 사용한다.

## 현재 적용된 설정 (`lua/configs/options.lua` 및 `init.lua`)

```lua
-- ==========================================================================
-- 0. 리더 키 설정 (init.lua — lazy.nvim 로드 전에 선언 필수)
-- ==========================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ==========================================================================
-- 1. 탭 및 들여쓰기 설정 (Tabs & Indentation)
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
vim.opt.cursorline = true     -- 커서가 위치한 줄에 하이라이트 표시
vim.opt.termguicolors = true  -- 24비트 RGB 트루컬러 지원
vim.opt.signcolumn = "yes"    -- 좌측에 Git(gitsigns) 및 에러(LSP/DAP) 아이콘 공간 항상 확보
vim.opt.scrolloff = 8         -- 커서 위아래로 최소 8줄 여유 공간 유지
vim.opt.sidescrolloff = 8     -- 가로 스크롤 시 커서 좌우로 최소 8칸 여유 공간 유지
vim.opt.wrap = false          -- 긴 줄 자동 줄바꿈 비활성화
vim.opt.cmdheight = 0         -- 평소 하단 명령줄 숨김 (매크로 녹화 표시는 lualine이 담당)
vim.opt.showmode = false      -- 기본 모드 표시 숨김 (lualine과 중복 방지)
vim.opt.laststatus = 3        -- 분할 창이 여러 개여도 하단 상태바는 전역 1개만 표시
vim.opt.showtabline = 0       -- 상단 기본 탭라인 숨김 (dropbar + harpoon + workspace 사용)

-- ==========================================================================
-- 3. 검색 및 매칭 설정 (Search & Matching)
-- ==========================================================================
vim.opt.hlsearch = true   -- 검색 매칭된 단어에 하이라이트 유지
vim.opt.incsearch = true  -- 타이핑하는 동안 실시간 매칭 이동
vim.opt.ignorecase = true -- 검색 시 대소문자 무시
vim.opt.smartcase = true  -- 대문자가 포함되면 대소문자 엄격 구분
vim.opt.showmatch = true  -- 닫는 괄호 입력 시 매칭되는 여는 괄호 표시

-- ==========================================================================
-- 4. 시스템 및 성능 설정 (System & Performance)
-- ==========================================================================
vim.opt.clipboard = "unnamedplus" -- 시스템 클립보드와 연동 (WSL에서는 clip.exe / Get-Clipboard 자동 연결)
vim.opt.mouse = "a"               -- 모든 모드에서 마우스 스크롤/클릭 허용
vim.opt.updatetime = 250          -- CursorHold 및 swap/gitsigns 갱신 대기 시간 (ms)
vim.opt.timeoutlen = 1000         -- 복합 단축키(which-key 포함) 다음 입력 대기 시간 (ms)
vim.opt.swapfile = false          -- .swp 파일 비활성화
vim.opt.backup = false            -- 백업 파일 비활성화
vim.opt.undofile = true           -- 종료 후 재실행해도 Undo 히스토리 영구 보존
vim.opt.fileencoding = "utf-8"    -- 기본 파일 저장 인코딩

-- ==========================================================================
-- 5. 창 분할, 자동완성 팝업 및 netrw 비활성화
-- ==========================================================================
vim.opt.splitright = true     -- 수직 분할 시 오른쪽에 새 창 열기
vim.opt.splitbelow = true     -- 수평 분할 시 아래쪽에 새 창 열기
vim.opt.pumheight = 10        -- 기본 팝업 메뉴 최대 높이 10줄
vim.opt.wildmenu = true       -- 명령줄 자동완성 메뉴 활성화
vim.opt.wildoptions = "pum"   -- 명령줄 자동완성을 팝업 메뉴 형태로 표시

-- 구형 netrw 비활성화 (stevearc/oil.nvim 으로 대체)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
```
