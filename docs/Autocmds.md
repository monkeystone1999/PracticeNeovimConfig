# vim.api.nvim_create_autocmd 인터페이스

## 값 
- vim.api.nvim_create_autocmd(event, opts)

| 파라미터 | 내용 |
| --- | --- |
| event | 이벤트 이름이며 무조건 문자열로 되어있다 |
| opts | 세부설정을 담은 테이블이며 주로 2가지 키를 사용한다 (pattern = 이벤트를 감지할 파일이름 혹은 특정 확장자, callback = 이벤트 발생시 실행할 함수) | 


## 예시
