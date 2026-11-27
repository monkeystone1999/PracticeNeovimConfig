# Usage Guide (사용법 총정리)

이 문서는 현재 Neovim 설정의 모든 주요 단축키, 명령어, 워크플로우를 기능별로 정리한 실전 사용 가이드입니다.  
기본 `<leader>` 키는 **`Space`**, `<localleader>` 키는 **`\`** 입니다.

> 기억나지 않는 단축키는 노멀 모드에서 `<Space>`를 누르고 잠시 기다리거나, **`<leader>?`** 를 눌러 현재 버퍼의 로컬 키맵(`which-key`)을 바로 확인할 수 있습니다.

---

## 1. 대시보드 & 워크스페이스 (`lua/custom/`)

터미널 크기에 따라 **3단(Full, `>=160칸`) / 2단(Half, `80~159칸`) / 단일(Quarter, `<80칸`)** 레이아웃으로 자동 전환되는 자체 대시보드와 탭(`tcd`) 기반 세션 관리 시스템입니다.

### 전역 단축키 및 명령어

| 키 / 명령어 | 동작 |
| :--- | :--- |
| `<leader>db` 또는 `:Dashboard` | 반응형 대시보드 열기 / 닫기 토글 |
| `<leader>ws` | 플로팅 워크스페이스 목록 창 열기 |
| `:WorkspaceInitDocs [이름]` | 현재 경로(`tcd`)에 `README.md` + `docs/` 생성 및 워크스페이스/Obsidian 자동 등록 |
| `:BufOnly` | 현재 보고 있는 버퍼만 남기고 나머지 열린 버퍼 일괄 정리 |

### 대시보드 / 워크스페이스 패널 내부 키맵

| 패널 | 키 | 동작 |
| :--- | :--- | :--- |
| **공통** | `<Left>`/`<Right>`/`<Up>`/`<Down>` 또는 `<C-h/j/k/l>` | 대시보드 패널 간 포커스 이동 |
| | `t` (Half 모드) | 우측 패널을 `Vim/Nvim Processes` ↔ `Workspaces` 전환 |
| | `<Esc>` / `q` | 대시보드 또는 서브 패널 닫기 |
| **Project 패널** | `e` / `f` / `g` / `q` | Oil 탐색기 / 파일 찾기 / 텍스트 검색 / Neovim 종료 |
| **Workspaces 패널** | `<CR>` | 선택한 워크스페이스 세션 로드 (현재 워크스페이스 자동 스냅샷 저장) |
| | `s` / `a` | 현재 상태 스냅샷 저장 / 새 워크스페이스 경로·이름 등록 |
| | `c` / `C` | 현재 탭의 `tcd`만 변경 / 등록된 워크스페이스의 실제 경로 이전(Relocate) |
| | `r` / `d` | 워크스페이스 이름 변경 / 워크스페이스 및 세션 파일 삭제 |
| **Vim/Nvim Processes** | `r` / `<CR>` | 목록 새로고침 / 백그라운드(`[BG]`/`[STOPPED]`) Neovim 세션을 현재 창으로 가져오기 |

---

## 2. 탐색 · 빠른 이동 · 파일 고정

상단 버퍼 탭라인(`showtabline = 0`)을 숨기는 대신 **Dropbar(브레드크럼)** + **Harpoon(핵심 파일 핀)** + **Telescope(퍼지 검색)** + **Flash(화면 점프)** 조합으로 빠르게 이동합니다.

### 파일 / 텍스트 검색 (`telescope.nvim` & `oil.nvim`)

| 키 | 동작 |
| :--- | :--- |
| `<leader>e` | 현재 파일 위치 기준으로 **Oil** 플로팅 디렉터리 편집기 열기 (`-`: 상위 폴더, `<CR>`: 열기, `:w`: 파일 생성/이름변경/삭제 반영) |
| `<leader>ff` | 프로젝트 파일 검색 (`find_files`) |
| `<leader>fg` | 프로젝트 내 실시간 문자열 검색 (`live_grep`) |
| `<leader>fb` | 현재 열린 버퍼 목록 검색 (`buffers`) |
| `<leader>fr` | 최근 열었던 파일 검색 (`oldfiles`) |
| `<leader>ft` | 프로젝트 내 `TODO` / `FIXME` / `NOTE` 주석 검색 (`TodoTelescope`) |
| `<leader>fh` | Neovim 도움말 태그 검색 (`help_tags`) |
| `<leader>fc` / `<leader>:` | 명령어 팔레트 검색 (`commands`) |

> Telescope 창 내부에서는 `<C-j>` / `<C-k>`로 위아래 이동, `<C-c>` 또는 노멀 모드 `q`로 닫을 수 있습니다.

### 화면 점프 (`flash.nvim`) & 상단 심볼 탐색 (`dropbar.nvim`)

| 키 | 모드 | 동작 |
| :--- | :---: | :--- |
| `s` | `n`, `x`, `o` | **Flash 점프**: 검색할 1~2글자 입력 후 화면에 표시된 라벨 알파벳을 눌러 즉시 이동 |
| `S` | `n`, `x`, `o` | **Flash Treesitter**: 현재 커서 주변 함수·블록·식 등의 구문 노드를 라벨로 즉시 선택 |
| `r` | `o` | **원격(Remote) 조작**: 예) `yr` + 점프 라벨 + `iw` 입력 시 커서를 유지한 채 멀리 있는 단어 복사 |
| `R` | `o`, `x` | 검색어 입력 후 해당 위치의 Treesitter 범위를 선택 |
| `<leader>;` | `n` | 상단 Winbar(Dropbar) 브레드크럼에서 폴더/클래스/함수 심볼 직접 선택 |
| `[;` / `];` | `n` | 현재 컨텍스트 시작으로 이동 / 다음 컨텍스트 선택 |
| `[x` | `n` | 상단 고정 컨텍스트(`treesitter-context`) 기준 상위 스코프로 점프 (`2[x` 등 숫자 접두사 지원) |

### 핵심 파일 핀 고정 (`harpoon` v2)

탭 워크스페이스(`tcd`) 경로마다 별도의 핀 목록이 자동 유지됩니다. 자주 오가는 `.h`와 `.cpp` 3~4개를 등록해 두면 가장 빠릅니다.

| 키 | 동작 |
| :--- | :--- |
| `<leader>ha` | 현재 파일을 Harpoon 목록에 추가 |
| `<leader>hh` | Harpoon 고정 목록 편집 창 열기/닫기 (일반 버퍼처럼 줄 순서 변경·삭제 가능) |
| `<leader>1` ~ `<leader>4` | 1번 ~ 4번 고정 파일로 즉시 전환 |
| `<leader>hp` / `<leader>hn` | 이전 / 다음 Harpoon 고정 파일로 순환 |

---

## 3. 코드 편집 · 포맷팅 · 문서화

### 괄호 / 따옴표 편집 (`mini.surround` & `nvim-autopairs`)

> `flash.nvim`의 `s` 점프 키와 입력 대기 충돌이 발생하지 않도록 Surround는 **`gs` 접두사**를 사용합니다.

| 키 예시 | 동작 |
| :--- | :--- |
| `gsaiw"` | 현재 단어(`iw`)를 큰따옴표(`"..."`)로 감싸기 |
| `(Visual) gsa)` | 선택한 영역을 소괄호(`(...)`)로 감싸기 |
| `gsd"` / `gsd)` | 주변의 큰따옴표 / 소괄호만 삭제 |
| `gsr"'` / `gsr)<` | 주변 `"`를 `'`로 교체 / `(...)`를 `<...>`로 교체 |
| `gsf` / `gsF` / `gsh` | 오른쪽·왼쪽 괄호 찾기 / 주변 괄호 하이라이트 |
| `<M-e>` (Insert 모드) | 커서 뒤에 있는 표현식을 원하는 괄호 위치까지 빠르게 감싸기 (`fast_wrap`) |

> 함수(`af`/`if`), 클래스(`ac`/`ic`), 매개변수(`aa`/`ia`), 조건·루프(`ao`/`io`), 템플릿(`a<`/`i<`) 선택 및 `]f`/`[f` 이동은 [`TextObjectsMotion.md`](./TextObjectsMotion.md)를 참고하세요.

### 포맷팅 (`conform.nvim`) & Doxygen 주석 (`neogen`)

| 키 / 명령어 | 동작 |
| :--- | :--- |
| `<leader>cf` | 현재 버퍼 또는 선택 영역 코드 포맷팅 (`stylua`, `clang-format`, `gersemi`, `ruff`, `prettier` 등) |
| `<leader>tf` | 파일 저장 시 자동 포맷(Format on Save) 전역 켜기/끄기 토글 |
| `:FormatDisable[!]` / `:FormatEnable` | 자동 포맷 비활성화 (`!` 붙이면 현재 버퍼만 비활성화) / 다시 활성화 |
| `<leader>nf` | 현재 커서 위치(함수/클래스) Doxygen 주석 생성 (`<Tab>` / `<S-Tab>`으로 자리표시자 이동) |
| `<leader>nc` / `<leader>nF` | 클래스·구조체 / 파일 상단 Doxygen 주석 템플릿 생성 |

---

## 4. LSP · 자동완성 · 에러 패널

### 자동완성 (`blink.cmp` + `friendly-snippets`)

| 키 (Insert 모드) | 동작 |
| :--- | :--- |
| `<Tab>` / `<S-Tab>` | 다음/이전 자동완성 항목 선택 또는 스니펫 필드 점프 |
| `<CR>` | 선택한 자동완성 항목 확정 |
| `<C-Space>` | 자동완성 메뉴 및 상세 문서 수동 열기/닫기 |
| `<C-k>` | 함수 시그니처 도움말 토글 |
| `<C-e>` | 자동완성 취소 및 닫기 |

### LSP 탐색 & 리팩터링 (`nvim-lspconfig` + `clangd_extensions`)

| 키 | 동작 |
| :--- | :--- |
| `gd` / `gD` | 정의(Definition)로 이동 / 선언(Declaration)으로 이동 |
| `gr` / `K` | 참조(References) 보기 / 커서 심볼 Hover 문서 팝업 |
| `<leader>rn` | 심볼 이름 일괄 변경 (Rename) |
| `<leader>ca` | 코드 액션 실행 (`telescope-ui-select` 드롭다운으로 표시) |
| `<leader>d` | 현재 줄 진단(에러/경고) 플로팅 팝업 보기 |
| `<leader>th` | Inlay Hints(추론 타입·매개변수 힌트) 표시 토글 |
| `<leader>ch` | **[C/C++]** 소스(`.cpp`) ↔ 헤더(`.h`/`.hpp`) 즉시 전환 |
| `<leader>cA` / `ci` / `cth` | **[C/C++]** AST 트리 보기 / 심볼 상세 정보 / 타입 계층 구조(Type Hierarchy) |

### 에러 · 심볼 · TODO 패널 (`trouble.nvim` & `todo-comments.nvim`)

| 키 | 동작 |
| :--- | :--- |
| `<leader>xx` / `<leader>xX` | 워크스페이스 전체 진단 목록 / 현재 버퍼 진단 목록 토글 |
| `<leader>xs` | 현재 파일 심볼(클래스·함수·변수) 아웃라인 트리 토글 |
| `<leader>xr` | 커서 심볼의 LSP 정의·참조·구현·타입 목록 우측 창 토글 |
| `<leader>xQ` / `<leader>xL` | Quickfix 목록 / Location 목록 토글 |
| `[q` / `]q` | 이전 / 다음 Trouble 항목(닫혀 있으면 Quickfix 항목)으로 점프 |
| `]t` / `[t` | 다음 / 이전 `TODO`·`FIXME`·`HACK`·`NOTE` 주석으로 이동 |
| `<leader>xt` / `<leader>xT` | 전체 TODO Trouble 목록 / 핵심(`TODO`, `FIX`, `FIXME`) 필터 목록 |

---

## 5. C/C++ 빌드 & 디버깅 (`cmake-tools` · `overseer` · `nvim-dap`)

CMake 구성 시 **Ninja 제너레이터**와 **멀티코어 병렬 빌드(`--parallel`)** 를 기본 사용하며, 하단 상태바(`lualine`)에 현재 `[빌드타입 | 빌드타겟 ▶ 실행타겟]` 상태가 실시간으로 표시됩니다.  
또한 터미널에서 `cmake -B build/release_x86` 처럼 커스텀 폴더에 빌드를 생성하더라도, 하위 빌드 폴더들의 수정 시각(`mtime`)을 자동 비교해 **가장 최근에 생성된 `compile_commands.json`을 프로젝트 루트에 링크(Linux)/복사(Windows)** 하여 `clangd`에 즉시 반영합니다.

### CMake & Overseer 빌드/실행

| 키 | 동작 |
| :--- | :--- |
| `<leader>cg` | `CMakeGenerate` — Ninja 구성 및 `compile_commands.json` 생성·루트 연결 |
| `<leader>cy` | `CMakeSelectBuildType` — 빌드 타입 선택 (`Debug`, `Release` 등) |
| `<leader>ct` / `<leader>cl` | 빌드 타겟 선택 / 실행·디버그 타겟 선택 |
| `<leader>cb` / `<leader>cc` | `CMakeBuild` (병렬 빌드, 하단 Overseer 창) / `CMakeClean` (클린) |
| `<leader>cr` / `<leader>cd` | `CMakeRun` (입력 가능한 하단 터미널 실행) / `CMakeDebug` (DAP 디버거 진입) |
| `<leader>cR` / `<leader>cD` | 현재 열려 있는 `.cpp` 파일이 속한 타겟만 즉시 실행 / 즉시 디버그 |
| `<leader>cL` | `CMakeTargetSettings` — 실행 타겟의 CLI 인자(`args`) 및 환경변수(`env`) 편집 |
| `<leader>cT` | `CMakeRunTest` — CTest 단위 테스트 목록 선택 실행 |
| `<leader>cx` | 진행 중인 CMake 빌드 또는 실행 작업 강제 중지 |
| `<leader>cs` / `<leader>cS` | 여러 빌드 폴더의 `compile_commands.json` 중 직접 선택 연결 / 최신(`mtime`) 강제 동기화 |
| `<leader>ot` / `<leader>or` | Overseer 빌드 태스크 창 토글 / 커스텀 태스크 실행 |

### 디버거 제어 (`nvim-dap` + `nvim-dap-ui`)

| 키 | 대체 키 | 동작 |
| :--- | :--- | :--- |
| `<leader>b` / `<leader>B` | - | 일반 중단점(Breakpoint) 토글 / 조건부 중단점 설정 |
| `<F5>` | `<leader>dc` | 디버깅 시작 / 다음 중단점까지 계속 실행 (`Continue`) |
| `<F10>` | `<leader>do` | 다음 줄 실행 (`Step Over`) |
| `<F11>` | `<leader>di` | 함수 내부로 진입 (`Step Into`) |
| `<F12>` | `<leader>dO` | 현재 함수 밖으로 나오기 (`Step Out`) |
| `<leader>de` | - | 커서 아래 변수 또는 비주얼 선택 식의 값 평가 (`Eval`) |
| `<leader>du` / `<leader>dt` | - | DAP UI 레이아웃 수동 토글 / 디버깅 세션 강제 종료 (`Terminate`) |

> 디버깅이 시작되면 `nvim-dap-ui` 창이 자동으로 열리고 종료 시 자동으로 닫히며, DAP 보조 창 어디서든 `q` 또는 `<Esc>`로 UI를 한 번에 닫을 수 있습니다.

---

## 6. Git · 터미널 · UI 토글

### Git (`gitsigns.nvim` & `lazygit.nvim`)

| 키 | 동작 |
| :--- | :--- |
| `<leader>lg` | **LazyGit** 전체 플로팅 창 열기 (커밋, 브랜치, 리베이스, 스태시) |
| `]h` / `[h` (`]H` / `[H`) | 다음 / 이전 (마지막 / 첫 번째) 변경 블록(Hunk)으로 이동 |
| `<leader>ghs` / `<leader>ghr` | 현재 Hunk(또는 비주얼 선택 줄) 스테이징 / 변경사항 되돌리기 |
| `<leader>ghS` / `<leader>ghR` | 현재 파일 전체 스테이징 / 전체 변경사항 초기화 |
| `<leader>ghu` | 직전 Hunk 스테이징 취소 |
| `<leader>ghp` | 변경 전/후 내용을 코드 줄 아래에 인라인 미리보기 |
| `<leader>ghb` / `<leader>ghd` | 현재 줄 상세 Blame 팝업 / 현재 파일 Git Diff 분할 비교 |
| `ih` (`o`, `x` 모드) | Git Hunk 텍스트 오브젝트 (예: `vih`로 변경 블록만 선택, `dih`로 삭제) |

### 터미널 및 전역 토글 (`<leader>t*` 계열)

| 키 | 동작 |
| :--- | :--- |
| `<leader>tt` | 현재 편집 중인 파일의 폴더 경로에서 **새 플로팅 터미널** 열기 |
| `<leader>tT` | 작업 상태를 유지한 채 **기존 플로팅 터미널** 열기/닫기 토글 (내부 `<Esc>`로 즉시 숨김) |
| `<leader>tb` / `<leader>tw` | Git 현재 줄 인라인 Blame 토글 / 단어 단위 Diff 강조 토글 |
| `<leader>tc` / `<leader>tC` | 상단 고정 컨텍스트(`treesitter-context`) 표시 토글 / 기준 모드(`cursor` ↔ `topline`) 전환 |
| `<leader>th` / `<leader>tf` | LSP Inlay Hints 토글 / 저장 시 자동 포맷(`conform`) 토글 |
