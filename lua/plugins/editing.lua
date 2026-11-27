return {
    -- 1. 괄호·따옴표·템플릿(< >) 감싸기/교체/삭제 (Surround)
    -- flash.nvim 의 's' 점프 단축키와 대기시간(timeoutlen) 충돌이 없도록 'gs*' 접두사 사용
    {
        "echasnovski/mini.surround",
        version = false,
        event = "VeryLazy",
        opts = {
            mappings = {
                add = "gsa", -- 감싸기 추가 (예: gsaiw" , 비주얼 선택 후 gsa) )
                delete = "gsd", -- 감싸기 삭제 (예: gsd" , gsd) )
                find = "gsf", -- 오른쪽 닫는 괄호 찾기
                find_left = "gsF", -- 왼쪽 여는 괄호 찾기
                highlight = "gsh", -- 주변 괄호 강조 표시
                replace = "gsr", -- 감싸기 교체 (예: gsr"' , gsr)< )
                update_n_lines = "gsn", -- 탐색 줄 범위 업데이트
            },
        },
    },

    -- 2. 자동 괄호 닫기 및 C/C++ 중괄호 스마트 개행 (Autopairs)
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {
            check_ts = true, -- Treesitter 연동 (주석/문자열 내부에서 불필요한 자동 닫기 방지)
            ts_config = {
                lua = { "string" },
                javascript = { "template_string" },
            },
            fast_wrap = {
                map = "<M-e>", -- 입력 모드에서 Alt+e 로 뒤쪽 표현식을 빠르게 괄호로 감싸기
            },
        },
    },
}
