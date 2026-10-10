# Neovim 기본 설정 및 API 사용법

## Text Objects & Motions
- 고급 사용자를 위한 특수한 동작 모음
- [examples](./TextObjectsMotion.md)

## Follow Tutorial


## 설정 변수 Options 제어
- vim.opt 를 사용하여 기본 동작을 제어
- [examples](./Options.md)

## 키 매핑 Keymaps
- vim.keymap.set 함수를 통해 사용자의 키보드 입력을 Lua 함수로 라우팅
- [examples](./Keymaps.md)

## 이벤트 구독 Autocmds
- vim.api.nvim_create_autocmd 를 사용해서 특정 이벤트를 감지하여 동작을 실행시키는 Callback 형식
- [examples](./Autocmds.md)

## 버퍼
- vim.api.nvim_*_buf 를 사용해 버퍼 활용
- [examples](./Buffers.md)

## Current Working Directory CWD
- 

# 기본 명령어 변경
## mark & jump
- m{a-z} Set mark => ms{a-z}
- m{A-Z} Set Global mark => ms{A-Z}
- `{a-z && A-Z} Go Mark => mg{a-z && A-Z}
## macro
- q{a-z} record set => rs{a-z}
- @{a-z} recprd play => rp{a-z}

# neovim
```lua
workspace = {
    tcd : {{buffer_number : filename}, {buffer_number : filename}, ...},
    tcd 2 : {{buffer_number : filename}, {buffer_number : filename}, ...},
}
```

# Tabline
- 그저 tcd 정보만 품고 있음 절대 경로
# winbar
- filename 만 표현 Tabpage 마다 표현하는 buffer 들이 달라야함 하지만 하나의 buffer 를 2개 이상의 Tabpage 에서 사용을 한다면 그것도 가능해야함
# statusbar
- 전체 내용의 몇 % 에 위치해있는지 현재 mode 만 표시
# cmdline
- vim.opt.cmdheight = 0         -- 하단 명령줄 창의 높이 (0으로 설정 시 평소엔 숨김 가능)
- floating window 를 사용하여 noice.nvim 과 유사하게 사용
- 명령어 자동 완성이 필요함
- 

# netrw
- Tabline 으로부터 buffername 을 받음 해당 tcd 의 절대경로를 buffername 으로 지정

# which-key like
- keymap.set 에 있는 opt 의 desc 의 내용을 다 끌어오기

# keymap
- 모든 동작은 <leader\> 를 베이스로 움직임
## netrw
- <leader\>e : toggle base open netrw
- <leader\>cw : workspace change (change current locate tcd)
- a : add new file or directory
- d : delete file or directory
- r : set current directory the highnest locate

## window
- <leader\>wsv : split the window vertical
- <leader\>wsh : split the window horizon
- <leader\>w{h,j,k,l} : move window
- <leader\>wc : close window
- <leader\>wac : all close window
- <leader\>wn : next window
- <leader\>wp : previous window

## tabpage
- <leader\>ta : add tabpage
- <leader\>t{h,l} : move tabpage
- <leader\>tc : close tabpage
- <leader\>tac : all close tabpage
- <leader\>tn : next tabpage
- <leader\>tp : previous tabpage

## LSP
- <leader\>sd : go to Definition (symbol)
- <leader\>sD : go to Declartion
- <leader\>sr : go to References
- <leader\>si : go to Implementation
- <leader\>dn : next diagnostic
- <leader\>dp : previous diagnostic
- <leader\>scn : symbol change name

## Telescope (Fuzzy Finder)
- <leader\>ff : Find Files
- <leader\>fg : Find string in files
- <leader\>fb : find open buffers
- <leader\>fh : find help tags
