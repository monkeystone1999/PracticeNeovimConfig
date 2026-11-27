# Neovim Configuration

## Description

[lazy.nvim](https://github.com/folke/lazy.nvim) 기반의 개인 Neovim 설정입니다. **C/C++ 개발**, **Lua 설정 작성**, **노트(Obsidian) 작성**을 중심으로 구성되어 있습니다.

- **LSP / 자동완성 / 포맷팅**: `nvim-lspconfig`, `mason.nvim`, `blink.cmp` (+ `friendly-snippets`), `clangd_extensions.nvim`, `lazydev.nvim`, `conform.nvim`
- **C/C++ 빌드 & 디버깅**: `cmake-tools.nvim`, `overseer.nvim`, `nvim-dap` (`nvim-dap-ui`, `nvim-dap-virtual-text`, `codelldb`), `neogen` (Doxygen)
- **탐색 / 이동 / 핀 고정**: `telescope.nvim` (+ `fzf-native`, `ui-select`), `oil.nvim`, `dropbar.nvim`, `flash.nvim`, `harpoon` (`harpoon2`), `which-key.nvim`
- **문법 / 텍스트 오브젝트 / 편집**: `nvim-treesitter` (`main`), `nvim-treesitter-context` (C/C++ 확장 쿼리), `nvim-treesitter-textobjects`, `mini.ai`, `mini.surround`, `nvim-autopairs`
- **진단 / Git / 노트 / UI**: `trouble.nvim`, `todo-comments.nvim`, `gitsigns.nvim`, `lazygit.nvim`, `obsidian.nvim`, `render-markdown.nvim`, `lualine.nvim`, `nvim-notify`
- **자체 모듈** (`lua/custom/`): 탭(`tcd`) 단위 워크스페이스/세션 관리, 반응형 대시보드(Full/Half/Quarter), VSCode Dark+ 하이라이트 및 상태바 설정
- **플로팅 터미널**: `<leader>tt` (현재 파일 폴더에서 새로 열기) / `<leader>tT` (기존 터미널 토글)
- Windows에서는 `vswhere`로 MSVC 환경 변수를 자동 주입하며, VSCode(`vim.g.vscode`)에서는 설정을 로드하지 않습니다.

### 구조

```text
.
├── init.lua              # 진입점 (MSVC 환경 주입, lazy.nvim 부트스트랩, 커스텀 모듈 초기화)
├── install.sh            # 필수/권장 외부 도구 확인 스크립트
├── lazy-lock.json        # 플러그인 커밋 버전 고정
├── docs/                 # 사용법(Usage), 플러그인 의존성(Plugins), Neovim API 정리 문서
└── lua/
    ├── configs/          # options.lua, keymaps.lua (플로팅 터미널 포함)
    ├── custom/           # 워크스페이스, 반응형 대시보드, 상태바, VSCode Dark+ 하이라이트
    └── plugins/          # 기능별 lazy.nvim 플러그인 스펙 (22개 파일)
```

## Table of Contents

- [Description](#description)
- [Requirement](#requirement)
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)

## Requirement

| 도구 | 버전 | 용도 | 필수 |
| :--- | :--- | :--- | :---: |
| `nvim` | `>= 0.11.0` (`0.12+` 권장) | 코어 에디터, 내장 LSP/Treesitter/Snippet | ✅ |
| `git` | `>= 2.19.0` | `lazy.nvim` 부트스트랩, `gitsigns.nvim`, 플러그인 설치 | ✅ |
| `curl` | - | 파서 / LSP / 바이너리 다운로드 | ✅ |
| `tar`, `unzip`, `gzip` | - | Mason 및 Treesitter 패키지 압축 해제 | ✅ |
| `gcc`/`g++` 또는 `clang` (`cc`, `c++`), `make` | C99 / C++17 | Treesitter 파서, `telescope-fzf-native` 빌드 | ✅ |
| `tree-sitter` CLI | `>= 0.26.1` | `nvim-treesitter` (`main`) 파서 빌드 | ✅ |
| `rg` (ripgrep) | - | Telescope `live_grep`, `todo-comments.nvim` 검색 | ✅ |
| `cmake`, `ninja` | CMake `>= 3.20` | C/C++ 빌드 (`cmake-tools.nvim`) | C/C++ |
| `lazygit` | - | `<leader>lg` Git TUI | 권장 |
| `fd` | - | Telescope `find_files` 고속 탐색 | 권장 |
| Nerd Font | v3+ | UI 아이콘 표시 (`nvim-web-devicons`) | 권장 |

> `clangd`, `neocmake`, `codelldb`, `lua_ls` 등은 `mason.nvim`이 자동 설치하므로 별도 설치가 필요 없습니다. 포매터(`stylua`, `clang-format`, `gersemi`, `ruff`, `prettierd`)도 `:Mason`에서 설치할 수 있습니다.

## Installation

1. 기존 설정이 있다면 백업합니다.

   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. 저장소를 클론합니다.

   ```bash
   git clone <repository-url> ~/.config/nvim
   ```

3. Requirement 충족 여부를 확인합니다. (확인만 수행하며 아무것도 설치하지 않습니다.)

   ```bash
   bash ~/.config/nvim/install.sh
   ```

4. Neovim을 실행하면 `lazy.nvim`이 자동으로 부트스트랩되고 모든 플러그인과 LSP/디버거가 설치됩니다.

   ```bash
   nvim
   ```

> Requirement 자동 설치는 `install.sh`에 추후 추가될 예정입니다.

## Usage

기본 `<leader>`는 `Space`, `<localleader>`는 `\`입니다. 전체 워크플로우별 상세 가이드는 [`docs/Usage.md`](./docs/Usage.md)를 참고하세요.

| 분류 | 키 | 동작 |
| :--- | :--- | :--- |
| **대시보드 / 워크스페이스** | `<leader>db` / `<leader>ws` | 반응형 대시보드 토글 / 워크스페이스 목록 관리 |
| **검색 (`Telescope`)** | `<leader>ff` / `fg` / `fb` / `ft` | 파일 / 텍스트(Grep) / 버퍼 / TODO 주석 검색 |
| | `<leader>fh` / `fr` / `:` | 도움말 / 최근 파일 / 명령어 팔레트 |
| **탐색 / 이동 / 핀** | `<leader>e` / `<leader>;` | Oil 플로팅 파일 탐색기 / Dropbar 심볼 선택 |
| | `s` / `S` | Flash 화면 내 점프 / Treesitter 구문 선택 |
| | `<leader>ha` / `hh` / `1`~`4` | Harpoon 파일 고정 / 목록 토글 / 1~4번 즉시 이동 |
| **편집 (`Surround` / `Format`)** | `gsa` / `gsd` / `gsr` | 괄호·따옴표 추가 / 삭제 / 교체 (`mini.surround`) |
| | `<leader>cf` / `<leader>tf` | 코드 포맷팅 (`conform`) / 저장 시 자동 포맷 토글 |
| | `<leader>a` / `<leader>A` | 다음 / 이전 함수 매개변수와 순서 교환 |
| **LSP / 진단 (`Trouble`)** | `gd` / `gr` / `K` / `<leader>ca` | 정의 이동 / 참조 / 문서 보기 / 코드 액션 |
| | `<leader>xx` / `xX` / `xs` / `xr` | 전체 에러 / 파일 에러 / 심볼 트리 / LSP 참조 패널 |
| **Git (`Gitsigns` / `LazyGit`)** | `<leader>lg` | LazyGit 플로팅 창 열기 |
| | `]h` / `[h`, `<leader>ghs` / `ghr` / `ghp` | Hunk 이동, 스테이징 / 되돌리기 / 인라인 미리보기 |
| **C/C++ (`CMake` / `DAP`)** | `<leader>cg` / `cb` / `cr` / `cd` | CMake Generate(Ninja) / 병렬 Build / Run / Debug |
| | `<leader>cL` / `cT` / `cs` / `cx` | 타겟 인자·환경 설정 / CTest / `compile_commands` 선택 / 중지 |
| | `<F5>` / `<leader>b` / `<leader>du` | 디버깅 시작·계속 / 중단점 토글 / DAP UI 토글 |
| | `<leader>ch` / `<leader>nf` | 헤더·소스 전환 (`clangd`) / Doxygen 주석 생성 |
| **터미널 / 태스크** | `<leader>tt` / `<leader>tT` | 현재 파일 폴더에서 새 터미널 / 기존 터미널 토글 |
| | `<leader>ot` / `<leader>or` | Overseer 빌드·실행 태스크 창 토글 / 실행 |

- 플러그인 관리: `:Lazy`, LSP/DAP/포매터 관리: `:Mason`
- 실시간 키맵 힌트는 `<leader>` 입력 후 대기하거나 `<leader>?`(버퍼 로컬 키맵)로 확인할 수 있습니다.

## Documentation

[`docs/`](./docs) 디렉터리에서 설정 상세 가이드와 Neovim Lua API 문서를 확인할 수 있습니다.

- **실사용 & 아키텍처 가이드**
  - [Usage.md](./docs/Usage.md) — 워크플로우별 상세 사용법, 단축키, 사용자 명령어 총정리
  - [Plugins.md](./docs/Plugins.md) — 전체 플러그인 목록, 의존성 그래프, `lazy.nvim`에서 플러그인들이 서로 의존·연동하는 원리
  - [TextObjectsMotion.md](./docs/TextObjectsMotion.md) — `mini.ai`, `mini.surround`, Treesitter 이동, `flash.nvim` 사용법
- **Neovim 설정 & Lua API 학습 노트**
  - [Preface.md](./docs/Preface.md) — 전체 목차 및 초기 설계/향후 구상 노트
  - [Options.md](./docs/Options.md) — `vim.opt` 설정 변수 정리
  - [Keymaps.md](./docs/Keymaps.md) — `vim.keymap.set` 인터페이스 및 실제 매핑 패턴
  - [Autocmds.md](./docs/Autocmds.md) — `vim.api.nvim_create_autocmd` 이벤트 및 실제 활용 예시
  - [Buffers.md](./docs/Buffers.md) — 스크래치 버퍼 생성 및 커스텀 UI 버퍼 제어
