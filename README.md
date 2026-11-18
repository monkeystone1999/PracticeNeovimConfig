# Neovim Configuration

## Description

[lazy.nvim](https://github.com/folke/lazy.nvim) 기반의 개인 Neovim 설정입니다. C/C++ 개발, Lua 설정 작성, 노트(Obsidian) 작성을 중심으로 구성되어 있습니다.

- **LSP / 자동완성**: `nvim-lspconfig`, `mason.nvim`, `blink.cmp`, `clangd_extensions.nvim`, `lazydev.nvim`
- **C/C++ 빌드 & 디버깅**: `cmake-tools.nvim`, `overseer.nvim`, `nvim-dap` (`nvim-dap-ui`, `codelldb`), `neogen` (Doxygen)
- **탐색 / 파일 관리**: `telescope.nvim` (+ fzf-native), `oil.nvim`, `which-key.nvim`
- **문법 / 텍스트 오브젝트**: `nvim-treesitter` (`main` 브랜치), `nvim-treesitter-textobjects`, `mini.ai`
- **Git / 노트 / UI**: `lazygit.nvim`, `obsidian.nvim`, `render-markdown.nvim`, `nvim-notify`, `bufferline`
- **자체 모듈** (`lua/custom/`): 탭(`tcd`) 단위 워크스페이스 버퍼 관리, 대시보드, winbar/lualine/highlight 설정
- **플로팅 터미널**: `<leader>tt` (현재 파일 폴더에서 새로 열기) / `<leader>tT` (토글)
- Windows에서는 `vswhere`로 MSVC 환경 변수를 자동 주입하며, VSCode(`vim.g.vscode`)에서는 설정을 로드하지 않습니다.

### 구조

```text
.
├── init.lua              # 진입점 (lazy.nvim 부트스트랩)
├── install.sh            # Requirement 확인 스크립트
├── lazy-lock.json        # 플러그인 버전 고정
├── docs/                 # Options, Keymaps, Autocmds, Buffers 등 학습 문서
└── lua/
    ├── configs/          # options.lua, keymaps.lua
    ├── custom/           # 워크스페이스, 대시보드, 상태바 등 자체 모듈
    └── plugins/          # lazy.nvim 플러그인 스펙
```

## Table of Contents

- [Title](#neovim-configuration)
- [Description](#description)
- [Requirement](#requirement)
- [Installation](#installation)
- [Usage](#usage)

## Requirement

| 도구 | 버전 | 용도 | 필수 |
| :--- | :--- | :--- | :---: |
| `nvim` | `>= 0.11.0` (`0.12+` 권장) | 코어 에디터, 내장 LSP/Treesitter | ✅ |
| `git` | `>= 2.19.0` | lazy.nvim 부트스트랩 및 플러그인 설치 | ✅ |
| `curl` | - | 파서 / LSP / 바이너리 다운로드 | ✅ |
| `tar`, `unzip`, `gzip` | - | Mason 및 Treesitter 패키지 압축 해제 | ✅ |
| `gcc`/`g++` 또는 `clang` (`cc`, `c++`), `make` | C99 / C++17 | Treesitter 파서, `telescope-fzf-native` 빌드 | ✅ |
| `tree-sitter` CLI | `>= 0.26.1` | `nvim-treesitter` (`main`) 파서 빌드 | ✅ |
| `rg` (ripgrep) | - | Telescope `live_grep` | ✅ |
| `cmake`, `ninja` | CMake `>= 3.20` | C/C++ 빌드 (`cmake-tools.nvim`) | C/C++ |
| `lazygit` | - | `<leader>lg` Git UI | 권장 |
| `fd` | - | Telescope `find_files` | 권장 |
| Nerd Font | v3+ | 아이콘 표시 | 권장 |

> `clangd`, `neocmake`, `codelldb`, `lua_ls` 등은 `mason.nvim`이 자동 설치하므로 별도 설치가 필요 없습니다.

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

4. Neovim을 실행하면 `lazy.nvim`이 자동으로 부트스트랩되고 플러그인이 설치됩니다.

   ```bash
   nvim
   ```

> Requirement 자동 설치는 `install.sh`에 추후 추가될 예정입니다.

## Usage

`<leader>`는 `Space`입니다.

| 키 | 동작 |
| :--- | :--- |
| `<leader>ff` / `fg` / `fb` | 파일 검색 / 텍스트 검색 / 버퍼 목록 |
| `<leader>fh` / `fr` / `fc` | 도움말 / 최근 파일 / 명령어 검색 |
| `<leader>:` | 명령어 팔레트 |
| `<leader>e` | Oil 플로팅 파일 탐색기 |
| `<leader>lg` | LazyGit |
| `<leader>tt` / `<leader>tT` | 현재 파일 폴더에서 새 터미널 / 터미널 토글 |
| `<leader>cg` / `cb` / `cr` / `cd` | CMake Generate / Build / Run / Debug |
| `<leader>cy` / `ct` / `cl` / `cc` | 빌드 타입 / 빌드 타겟 / 실행 타겟 선택 / Clean |
| `<leader>ot` / `<leader>or` | Overseer 태스크 창 토글 / 실행 |

- 플러그인 관리: `:Lazy`, LSP/DAP 도구 관리: `:Mason`
- 전체 키맵은 `which-key`(`<leader>` 입력 후 대기) 또는 [`lua/configs/keymaps.lua`](./lua/configs/keymaps.lua)에서 확인할 수 있습니다.
- 자세한 설명은 [`docs/`](./docs) 폴더를 참고하세요. ([Options](./docs/Options.md), [Keymaps](./docs/Keymaps.md), [Autocmds](./docs/Autocmds.md), [Buffers](./docs/Buffers.md))
