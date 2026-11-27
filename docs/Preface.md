# Neovim 문서 목차 및 설계 노트

## 1. 실사용 & 플러그인 구조 문서

- **전체 사용법 및 단축키 가이드**: [Usage.md](./Usage.md)
- **플러그인 아키텍처 및 의존성 원리**: [Plugins.md](./Plugins.md)
- **텍스트 오브젝트 & 모션 정리**: [TextObjectsMotion.md](./TextObjectsMotion.md)

## 2. Neovim 기본 설정 및 Lua API 레퍼런스

- **설정 변수 (`vim.opt`) 제어**: [Options.md](./Options.md)
- **키 매핑 (`vim.keymap.set`)**: [Keymaps.md](./Keymaps.md)
- **이벤트 구독 (`nvim_create_autocmd`)**: [Autocmds.md](./Autocmds.md)
- **버퍼 생성 및 관리 (`nvim_create_buf`)**: [Buffers.md](./Buffers.md)

---

## 3. 현재 구현된 자체 아키텍처 요약 (`lua/custom/`)

초기에 구상했던 핵심 아이디어들이 현재 아래와 같이 구현되어 동작하고 있습니다.

- **탭(`tcd`) 기반 워크스페이스 & 세션** ([`lua/custom/bases/workspace.lua`](../lua/custom/bases/workspace.lua), [`workspace_buffer.lua`](../lua/custom/workspace/workspace_buffer.lua))
  - 워크스페이스별 경로(`WorkspaceList.json`)와 세션 스냅샷(`sessions/*.vim`)을 분리 저장하며, 전환 시 미저장 버퍼 보호 및 `tcd` 강제 동기화를 수행합니다.
  - 등록된 모든 워크스페이스는 자동으로 `obsidian.nvim` 볼트(`README.md` + `docs/`)와 `harpoon` 핀 목록의 키(`vim.fn.getcwd(0)`)로 연동됩니다.
- **반응형 대시보드** ([`lua/custom/dashboard/dashboard.lua`](../lua/custom/dashboard/dashboard.lua))
  - 창 너비에 따라 Full(`>=160`) / Half(`80~159`) / Quarter(`<80`) 모드로 전환되며, 백그라운드 Vim/Neovim 프로세스의 세션을 RPC 소켓을 통해 현재 창으로 가져오는(Takeover) 기능을 포함합니다.
- **상단 Winbar / 하단 Statusline / 탐색기**
  - `showtabline = 0`으로 탭라인을 숨기고, 상단 문맥은 `dropbar.nvim`, 하단 전역 상태바(`laststatus = 3`)는 `lualine.nvim`(활성 워크스페이스, 매크로 녹화 `@reg`, 활성 LSP 표시)이 담당합니다.
  - 구형 `netrw`는 비활성화하고 `oil.nvim` 플로팅 탐색기(`<leader>e`)로 대체했습니다.

---

## 4. 초기 구상 및 향후 실험 아이디어 메모

> 아래 내용은 초기 설계 스케치 및 추후 키보드 레이아웃/매크로 커스터마이징 실험을 위해 남겨둔 개인 아이디어 노트입니다.

### 기본 명령어 리매핑 아이디어

#### mark & jump
- `m{a-z}` Set mark => `ms{a-z}`
- `m{A-Z}` Set Global mark => `ms{A-Z}`
- `` `{a-z && A-Z} `` Go Mark => `mg{a-z && A-Z}`
- mark 와 jump 를 toggle 형식으로 구성 검토

#### macro
- `q{a-z}` record set => `rs{a-z}`
- `@{a-z}` record play => `rp{a-z}`

### 워크스페이스 데이터 구조 스케치

```lua
workspace = {
    tcd = { { buffer_number = filename }, { buffer_number = filename } },
    tcd_2 = { { buffer_number = filename }, { buffer_number = filename } },
}
```

### cmdline 구상
- `vim.opt.cmdheight = 0` — 하단 명령줄 창의 높이를 0으로 두어 평소엔 숨김
- 추후 floating window 기반 cmdline UI(`noice.nvim` 또는 Neovim 내장 extui) 검토

### 하드웨어 레이어(F13~F22 / Super) 및 창 제어 구상

- `<Ctrl>` ---> `F13`
- `<leader>w` ---> `Super` (`F14`)
- `<Fn_Tab>` ---> `F15` (Tab Page)
- `<Fn_q>` ---> `F16` (Close all without unsaved file)
- `<Fn_e>` ---> Macro `{<Esc>:e }` (Editing new file)
- `<Fn_r>` ---> Macro `{<Esc>:restart}` (Reload Nvim)
- `<Fn_s>` ---> `F17` (Symbol search)
- `<Fn_d>` ---> `F19` (Debug)
- `<Fn_f>` ---> `F20` (Fzf)
- `<Fn_g>` ---> `F21` (Git)
- `<Fn_c>` ---> `F22` (CMake)

- `<Super>{h,j,k,l}` : 창 포커스 이동
- `<Super>n` / `<Super>p` : 다음 / 이전 창
- `<Super>q` / `<Super>aq` : 현재 창 닫기 / 전체 창 닫기
- `<Super>sv` / `<Super>sh` : 수직 / 수평 창 분할
- `<Super>-` / `<Super>=` : 창 크기 조절
- `<Super><Ctrl>{h,j,k,l}` : 창 위치 이동
