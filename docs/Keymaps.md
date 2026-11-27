# vim.keymap.set 인터페이스

## 값 대입
- vim.keymap.set(mode, lhs, rhs, opts)

| 매개변수 | 의미 |
| --- | --- |
| mode | 동작할 에디터의 모드 (Normal = 'n', Insert = 'i') |
| lhs | 사용자가 누를 키 문자열 (Left Hand Side) |
| rhs | 엔진이 실행할 명령어 문자열 또는 Lua 함수 (Right Hand Side) |
| opts | 매핑의 세부 동작을 제어하는 추가 옵션 테이블 (생략 가능) |

## 키보드 입력 : 키 문자열
Neovim에서 단축키를 설정할 때(`vim.keymap.set` 또는 `vim.api.nvim_set_keymap`의 두 번째 매개변수인 `{lhs}`) 입력하는 키 조합 문자열은 표기법(Keycode) 규칙을 따릅니다.

`<CR>`나 `<leader>`처럼 대소문자를 구분하지 않는 표기법을 통해 특수 키와 조합 키를 정의하며, 주요 구성요소는 다음과 같이 분류됩니다.

---

### 1. 수정자 키 (Modifier Keys)
다른 키와 함께 누르는 조합 키를 표기할 때 사용합니다.
* **`<C-key>`** (또는 `<CTRL-key>`): **Control** 키 조합 (예: `<C-s>`, `<C-a>`)
* **`<M-key>`** (또는 `<A-key>`): **Alt / Option** (Meta) 키 조합 (예: `<M-f>`, `<A-j>`)
* **`<S-key>`**: **Shift** 키 조합 (예: `<S-Tab>`, `<S-F1>`)
* **조합 중첩 가능**: `<C-M-x>` (Ctrl + Alt + x), `<C-S-f>` (Ctrl + Shift + f)

### 2. 리더 키 및 특수 접두사 (Leader & Special Prefix)
* **`<leader>`**: 사용자 정의 기본 리더 키 (`vim.g.mapleader`에 할당된 문자열 사용)
* **`<localleader>`**: 특정 파일타입/버퍼 전용 리더 키 (`vim.g.maplocalleader`)
* **`<Cmd>`**: 명령줄(Cmdline) 모드로 전환하는 화면 연출 없이 Ex 명령어를 직접 실행하는 특수 표기
* **`<Plug>`**: 플러그인 내부용 가상 키 매핑 표기

### 3. 주요 제어 및 특수 입력 키 (Control & Special Keys)
* **`<CR>`** (또는 `<Enter>`, `<Return>`): **Enter / Carriage Return** 키
* **`<Space>`**: **스페이스바** 키
* **`<Esc>`**: **Escape** 키
* **`<BS>`**: **Backspace** (지우기) 키
* **`<Tab>`**: **Tab** 키
* **`<Del>`**: **Delete** 키
* **`<LT>`**: 리터럴 `<` (Less-Than) 기호 문자 자체를 표현할 때 사용
* **`<NL>`**: **Newline** (줄바꿈) 문자
* **`<Nop>`**: 아무 동작도 수행하지 않음 (No Operation)

### 4. 방향키 및 이동 키 (Navigation Keys)
* **`<Up>`**, **`<Down>`**, **`<Left>`**, **`<Right>`**: 방향키 (상, 하, 좌, 우)
* **`<Home>`**, **`<End>`**: Home / End 키
* **`<PageUp>`**, **`<PageDown>`**: Page Up / Page Down 키

### 5. 기능 키 (Function Keys)
* **`<F1>` ~ `<F12>`**: 키보드 상단의 F1부터 F12까지의 기능 키

### 6. 마우스 입력 (Mouse Events)
* **`<LeftMouse>`**, **`<RightMouse>`**, **`<MiddleMouse>`**: 마우스 클릭
* **`<ScrollWheelUp>`**, **`<ScrollWheelDown>`**: 마우스 스크롤 휠

---

### 💡 사용 예시 

```lua
-- 1. Leader 키와 Enter(<CR>)를 이용한 파일 저장
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save file' })

-- 2. Control 키 조합
vim.keymap.set('n', '<C-s>', ':w<CR>')

-- 3. Alt + 방향키 조합
vim.keymap.set('n', '<M-Up>', ':m .-2<CR>')

-- 4. <Cmd> 표기를 활용해 커맨드라인 표시 없이 깔끔하게 실행
vim.keymap.set('n', '<leader>ff', '<Cmd>Telescope find_files<CR>')

-- 5. 리터럴 '<' 문자를 매핑할 때 (<LT> 활용)
vim.keymap.set('n', '<LT>a', 'echo "pressed <a"')
```

## 실제 설정 적용 패턴 (`lua/` 내 활용 예시)

전체 단축키 목록은 [`Usage.md`](./Usage.md)에 정리되어 있으며, 코드에서는 상황에 따라 아래 3가지 패턴을 구분해 사용합니다.

```lua
-- 1. 버퍼 로컬 키맵 (LspAttach, Gitsigns 등 해당 파일 버퍼에서만 동작해야 할 때)
vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", {
    buffer = ev.buf,
    silent = true,
    desc = "Switch Source/Header (C/C++)",
})

-- 2. 대기 시간 없는 즉시 반응 키맵 (대시보드/플로팅 터미널 등 전용 UI 창)
vim.keymap.set({ "t", "n" }, "<Esc>", close_float_term, {
    buffer = buf,
    silent = true,
    nowait = true, -- 다른 복합 키맵과 첫 글자가 겹쳐도 timeoutlen을 기다리지 않고 즉시 실행
})

-- 3. lazy.nvim 플러그인 스펙의 keys 테이블 (키를 처음 누를 때 플러그인 지연 로드)
keys = {
    {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Trouble: 워크스페이스 전체 에러/경고 목록",
    },
}
```
