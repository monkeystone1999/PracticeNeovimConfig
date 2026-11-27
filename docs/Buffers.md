# `vim.api.nvim_create_buf(listed, scratch)` 및 버퍼 관리

Neovim에서 화면에 보이는 모든 파일·패널·터미널은 메모리 상의 **버퍼(Buffer)** 로 표현되며, `nvim_create_buf`는 새 버퍼의 고유 숫자 ID(`bufnr`)를 반환합니다.

## 1. 매개변수 의미

- **`listed` (`boolean`)**: 일반 버퍼 목록(`:ls`, `:buffers`, Telescope `<leader>fb`)에 노출할지 여부 (`vim.bo[buf].buflisted`)
- **`scratch` (`boolean`)**: 실제 디스크 파일과 연결되지 않는 휘발성 임시(`nofile`) 버퍼로 생성할지 여부

> 대시보드, 워크스페이스 목록, 플로팅 터미널 같은 **보조 UI 창은 항상 `nvim_create_buf(false, true)` (`unlisted + scratch`)로 생성**해야 일반 파일 목록이나 `:BufOnly` 정리 대상에 섞이지 않습니다.

---

## 2. 자주 함께 설정하는 버퍼 옵션 (`vim.bo[buf]`)

| 옵션 | 주요 값 | 설명 |
| :--- | :--- | :--- |
| `buftype` | `""`, `"nofile"`, `"acwrite"`, `"terminal"` | 일반 파일(`""`), UI용 스크래치(`"nofile"`), 플러그인 저장 훅(`"acwrite"` — `oil.nvim` 등) 구분 |
| `bufhidden` | `"hide"`, `"wipe"`, `"delete"` | 창이 닫혔을 때 버퍼를 메모리에 유지할지(`"hide"`) 즉시 소거할지 결정 |
| `modifiable` | `true` / `false` | UI 렌더링 중에만 잠시 `true`로 열어 줄을 갱신하고, 평소에는 `false`로 잠가 오타 입력을 방지 |
| `buflisted` | `true` / `false` | 사용자 파일 탐색 목록 포함 여부 |

---

## 3. 현재 설정에서의 실제 활용처

1. **읽기 전용 UI 패널 렌더링** ([`lua/custom/workspace/workspace_buffer.lua`](../lua/custom/workspace/workspace_buffer.lua), [`lua/custom/dashboard/`](../lua/custom/dashboard))
   ```lua
   local buf = vim.api.nvim_create_buf(false, true)
   vim.bo[buf].bufhidden = "hide"
   vim.bo[buf].modifiable = true
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
   vim.bo[buf].modifiable = false
   ```
2. **현재 버퍼 외 일괄 정리 (`:BufOnly`)** ([`lua/custom/buffer.lua`](../lua/custom/buffer.lua))
   - `vim.bo[buf].buflisted == true`인 일반 파일 버퍼만 골라 `force = false`로 안전하게 닫으므로, 미저장 변경사항이 있는 파일과 대시보드/터미널 스크래치 버퍼는 보호됩니다.
3. **워크스페이스 전환 시 미저장 버퍼 검사** ([`lua/custom/bases/workspace.lua`](../lua/custom/bases/workspace.lua))
   - `buflisted`이면서 `modified == true`인 버퍼(일반 파일 및 `oil.nvim`의 `acwrite` 버퍼 포함)가 하나라도 있으면 세션 전환을 중단하고 파일 목록을 알림으로 표시합니다.
