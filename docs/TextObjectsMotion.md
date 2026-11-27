# Text Objects & Motions (텍스트 객체와 구문 이동)

Vim의 편집은 **`동작(Operator: d, c, y, v, gsa)` + `범위(Text Object / Motion)`** 의 조합으로 이루어집니다.  
현재 설정은 [`text_obj.lua`](../lua/plugins/text_obj.lua)(`mini.ai` + `nvim-treesitter-textobjects`), [`editing.lua`](../lua/plugins/editing.lua)(`mini.surround`), [`navigation.lua`](../lua/plugins/navigation.lua)(`flash.nvim`), [`gitsigns.lua`](../lua/plugins/gitsigns.lua)를 통해 C/C++ 및 코드 구조 단위의 정밀한 선택과 이동을 지원합니다.

---

## 1. Text Objects (범위 선택 및 조작)

`v`(선택), `d`(삭제), `c`(수정), `y`(복사), `gsa`(괄호 감싸기) 뒤에 붙여 사용합니다. (`a` = around 외곽 포함, `i` = inside 내부만)

### 기본 Vim 텍스트 객체 예시
- `iw` / `aw`: 단어 내부 / 공백 포함 단어 (`ciw`: 현재 단어 지우고 바로 입력)
- `i"` / `a"`, `i)` / `a)`, `i}` / `a}`: 따옴표·소괄호·중괄호 내부 / 괄호 포함 전체
- `it` / `at`: HTML·XML 태그(`<tag>...</tag>`) 내부 / 태그 포함 (예: `vit`)

### Treesitter & `mini.ai` 확장 텍스트 객체 ([`lua/plugins/text_obj.lua`](../lua/plugins/text_obj.lua))

| 텍스트 객체 | 대상 구문 | C/C++ 실전 활용 예시 |
| :--- | :--- | :--- |
| `af` / `if` | **함수 (`@function`)** 시그니처 포함 전체 / 본문 내부 | `daf` (함수 통째로 삭제), `vif` (함수 본문만 선택) |
| `ac` / `ic` | **클래스 · 구조체 (`@class`)** 전체 / 멤버 목록 내부 | `yac` (`struct`/`class` 정의 전체 복사) |
| `aa` / `ia` | **매개변수 · 인자 (`@parameter`)** 쉼표 포함 / 인자 값만 | `cia` (현재 인자만 수정), `daa` (쉼표까지 깔끔하게 인자 삭제) |
| `ao` / `io` | **블록 · 조건문 · 루프 (`if`, `for`, `while`, `{}`)** | `dio` (`for` 루프 안쪽 코드만 비우기) |
| `a<` / `i<` | **C++ 템플릿 꺾쇠 (`<...>`)** 균형 매칭 | `ci<` (`std::vector<const MyType*>` 안의 타입만 즉시 교체) |
| `ih` | **Git 변경 블록 (`gitsigns`)** | `vih` (수정한 줄 묶음 선택), `dih` (수정한 블록 삭제) |

> `mini.ai`의 `search_method = "cover_or_next"` 덕분에 커서가 함수나 `<...>` 바로 앞(같은 줄 왼쪽)에 있어도 자동으로 오른쪽 대상을 찾아 선택합니다.

### Surround 조작 (`mini.surround` — [`lua/plugins/editing.lua`](../lua/plugins/editing.lua))

- **`gsa{모션/객체}{문자}`**: 감싸기 추가 — 예: `gsaiw"` (단어를 `"..."`로), `gsaaf` 후 `{` (함수를 블록으로)
- **`gsd{문자}`**: 감싸는 괄호/따옴표 제거 — 예: `gsd)` (`(x + y)` → `x + y`)
- **`gsr{기존}{새문자}`**: 감싸는 기호 교체 — 예: `gsr"'` (`"str"` → `'str'`), `gsr)]` (`(i)` → `[i]`)
- **`gsf` / `gsF` / `gsh`**: 오른쪽·왼쪽 감싸는 기호로 이동 / 주변 괄호 하이라이트

---

## 2. Motions (구문 점프 및 스왑)

### 기본 모션
- `%`: 짝이 맞는 괄호(`()`, `{}`, `[]`) 및 `#if` / `#else` / `#endif` 사이 점프
- `f{문자}` / `t{문자}` (`F` / `T`): 현재 줄에서 특정 문자로 이동 / 직전까지 이동 (예: `dt;` — 세미콜론 직전까지 삭제)

### Treesitter 구문 점프 & 인자 교환 (`nvim-treesitter-textobjects`)

모든 구문 점프는 점프 리스트에 기록되므로 이동 후 **`<C-o>`** 로 언제든 원래 위치로 돌아올 수 있습니다.

| 키 | 동작 |
| :--- | :--- |
| `]f` / `[f` | 다음 / 이전 **함수 시작**으로 이동 |
| `]F` / `[F` | 다음 / 이전 **함수 끝(`}`)** 으로 이동 |
| `]c` / `[c` | 다음 / 이전 **클래스 / `struct` 시작**으로 이동 |
| `]a` / `[a` | 다음 / 이전 **함수 매개변수(인자)** 로 이동 |
| `<leader>a` / `<leader>A` | 현재 매개변수를 **오른쪽 / 왼쪽 매개변수와 즉시 위치 교환(Swap)** |
| `[x` | 현재 중첩 스코프(`#ifdef`, 루프, 람다, 함수, 네임스페이스)의 **상위 선언 줄로 점프** (`treesitter-context`) |

### 화면 전체 점프 (`flash.nvim`) & 항목 순회

| 키 | 동작 |
| :--- | :--- |
| `s` + 2글자 + 라벨 | 화면 내 보이는 어느 위치로든 3~4타 만에 순간이동 |
| `S` + 라벨 | 현재 커서를 감싸는 구문 노드(식 → 문장 → 루프 → 함수 → 클래스)를 단계별 라벨로 즉시 선택 |
| `]h` / `[h` | 다음 / 이전 **Git 변경 블록(Hunk)** 이동 (`gitsigns.nvim`) |
| `]t` / `[t` | 다음 / 이전 **TODO / FIXME 주석** 이동 (`todo-comments.nvim`) |
| `]q` / `[q` | 다음 / 이전 **Trouble 진단 항목 또는 Quickfix** 이동 (`trouble.nvim`) |
