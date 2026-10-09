# vim.keymap.set 인터페이스

## 값 대입
- vim.keymap.set(mode, lhs, rhs, opts)

| 매개변수 | 의미 |
| --- | --- |
| mode | 동작할 에디터의 모드 (Normal = 'n', Insert = 'i') |
| lhs | 사용자가 누를 키 문자열 (Left Hand Side) |
| rhs | 엔진이 실행할 명령어 문자열 또는 Lua 함수 (Right Hand Side) |
| opts | 매핑의 세부 동작을 제어하는 추가 옵션 테이블 (생략 가능) |

## 예시
