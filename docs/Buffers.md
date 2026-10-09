# vim.api.nvim_create_buf(listed, scratch)
- 반환 값은 버퍼의 ID 이다.

## listed : boolean
- 일반 버퍼 목록에 노출할지 여부 즉 :buffers 시 나타나는지 안 나타나는지
## scratch : boolean
- 실제 파일과 연결되지 않는 휘발성 임시버퍼인지