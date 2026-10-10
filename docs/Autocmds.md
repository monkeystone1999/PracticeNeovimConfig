# vim.api.nvim_create_autocmd 인터페이스

## 값 
- vim.api.nvim_create_autocmd(event, opts)

| 파라미터 | 내용 |
| --- | --- |
| event | 이벤트 이름이며 무조건 문자열로 되어있다 |
| opts | 세부설정을 담은 테이블이며 주로 2가지 키를 사용한다 (pattern = 이벤트를 감지할 파일이름 혹은 특정 확장자, callback = 이벤트 발생시 실행할 함수) | 

## 이벤트 종류
Neovim의 `vim.api.nvim_create_autocmd({event}, {opts})` 함수 첫 번째 매개변수 `{event}`에 사용할 수 있는 주요 오토커맨드 이벤트 종류는 기능과 동작 시점에 따라 다음과 같이 분류됩니다.

---

### 1. 버퍼 및 파일 처리 (Buffer & File)
* **`BufReadPre` / `BufReadPost` (또는 `BufRead`)**: 파일을 버퍼로 읽어오기 전/후
* **`BufWritePre` / `BufWritePost` (또는 `BufWrite`)**: 버퍼를 파일로 저장하기 전/후
* **`BufEnter` / `BufLeave`**: 버퍼에 진입하거나 이탈할 때
* **`BufWinEnter` / `BufWinLeave`**: 버퍼가 창(Window)에 표시되거나 사라질 때
* **`BufNewFile`**: 아직 존재하지 않는 새 파일 편집을 시작할 때
* **`BufUnload` / `BufDelete` / `BufWipeout`**: 버퍼가 메모리에서 해제되거나, 삭제되거나, 완전히 제거될 때

### 2. 텍스트 편집 및 모드 변경 (Text Editing & Mode)
* **`TextChanged` / `TextChangedI`**: 노멀 모드 / 인서트 모드에서 버퍼의 텍스트 내용이 변경되었을 때
* **`InsertEnter` / `InsertLeave`**: 인서트 모드 진입 / 이탈 시
* **`InsertCharPre`**: 인서트 모드에서 문자가 입력되기 직전
* **`ModeChanged`**: 편집 모드가 변경되었을 때 (예: `n:i` 노멀→인서트)
* **`TextYankPost`**: 텍스트를 복사(Yank)하거나 삭제한 직후

### 3. 커서 이동 및 대기 (Cursor Motion & Hold)
* **`CursorMoved` / `CursorMovedI`**: 노멀 모드 / 인서트 모드에서 커서가 이동했을 때
* **`CursorHold` / `CursorHoldI`**: 일정 시간(`updatetime`) 동안 키 입력 없이 정지해 있을 때

### 4. 창 및 탭 관리 (Window & Tab)
* **`WinEnter` / `WinLeave`**: 창에 진입하거나 이탈할 때
* **`WinNew` / `WinClosed`**: 새로운 창이 생성되거나 닫힐 때
* **`TabEnter` / `TabLeave`**: 탭 페이지 전환 시

### 5. 파일타입 및 설정 (FileType & Options)
* **`FileType`**: 파일타입이 감지되거나 설정되었을 때 (예: `lua`, `python`)
* **`OptionSet`**: `vim.opt` 설정값이 변경되었을 때
* **`ColorScheme`**: 컬러스킴 테마가 변경되었을 때

### 6. 세션 및 라이프사이클 (Session & Lifecycle)
* **`VimEnter`**: Neovim 실행 및 모든 설정 파일(.nvimrc / init.lua) 로드 완료 후
* **`VimLeavePre` / `VimLeave`**: Neovim 종료 프로세스 시작 전 / 종료 직전
* **`VimResized`**: 터미널이나 UI 창 크기가 변경되었을 때
* **`FocusGained` / `FocusLost`**: Neovim 창이 OS 포커스를 얻거나 잃었을 때

### 7. Neovim 내장 및 LSP 이벤트 (LSP & Special)
* **`LspAttach` / `LspDetach`**: LSP 서버가 버퍼에 연결되거나 해제될 때
* **`DiagnosticChanged`**: 내장 진단(에러, 경고) 정보가 갱신되었을 때
* **`User`**: 사용자 정의 이벤트 (`vim.api.nvim_exec_autocmd`로 직접 호출)

---

## 예시
